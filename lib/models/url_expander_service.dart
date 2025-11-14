

import 'package:dio/dio.dart';

class DioUrlExpanderService {
  static const int maxRedirects = 10;
  static final Dio _dio = Dio();
  
  // Configure Dio instance
  static void _configureDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      followRedirects: false, // We'll handle redirects manually
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
    );
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => print('[DioUrlExpander] $obj'),
    ));
  }

  static Future<String?> expandUrl(String shortUrl) async {
    _configureDio();
    
    try {
      String currentUrl = shortUrl;
      int redirectCount = 0;
      
      while (redirectCount < maxRedirects) {
        try {
          // Make a HEAD request to avoid downloading the full content
          final response = await _dio.head(
            currentUrl,
            options: Options(
              followRedirects: false,
              validateStatus: (status) {
                // Accept all status codes to handle redirects manually
                return status != null && status < 500;
              },
            ),
          );
          
          // Check if it's a redirect response
          if (response.statusCode != null && 
              response.statusCode! >= 300 && 
              response.statusCode! < 400) {
            
            final location = response.headers.value('location');
            if (location != null) {
              // Handle relative URLs
              if (location.startsWith('/')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              } else if (!location.startsWith('http')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}/${location}';
              } else {
                currentUrl = location;
              }
              redirectCount++;
              continue;
            }
          }
          
          // If we reach here, we either got a final response or no redirect
          break;
          
        } on DioException catch (e) {
          if (e.response?.statusCode != null && 
              e.response!.statusCode! >= 300 && 
              e.response!.statusCode! < 400) {
            // Handle redirect in error response
            final location = e.response!.headers.value('location');
            if (location != null) {
              if (location.startsWith('/')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              } else if (!location.startsWith('http')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}/${location}';
              } else {
                currentUrl = location;
              }
              redirectCount++;
              continue;
            }
          }
          
          print('Dio error expanding URL $currentUrl: ${e.message}');
          break;
        }
      }
      if (currentUrl.contains('google.com') || currentUrl.contains('googleusercontent.com')) {
        return await _extractGoogleImageUrl(currentUrl);
      }
      
      return currentUrl;
      
    } catch (e) {
      print('Error expanding URL $shortUrl: $e');
      return null;
    }
  }
  
  /// Extracts the actual image URL from Google Images redirect URLs
  static Future<String?> _extractGoogleImageUrl(String googleUrl) async {
    try {
      final response = await _dio.get(
        googleUrl,
        options: Options(
          followRedirects: true,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.data != null) {
        final html = response.data.toString();
        
        // Look for image URLs in the HTML with multiple patterns
        final imageUrlPatterns = [
          // Direct image URLs in quotes
          RegExp(r'"(https://[^"]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^"]*)?)"', caseSensitive: false),
          // Image URLs in src attributes
          RegExp(r'src="(https://[^"]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^"]*)?)"', caseSensitive: false),
          // Image URLs in CSS url() functions
          RegExp(r'url\((https://[^)]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^)]*)?)\)', caseSensitive: false),
          // Google Images specific patterns
          RegExp(r'"ou":"(https://[^"]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^"]*)?)"', caseSensitive: false),
          RegExp(r'imgurl=(https://[^&]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^&]*)?)', caseSensitive: false),
          // Encoded URLs
          RegExp(r'\\u003d(https://[^\\]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\\]*)?)', caseSensitive: false),
        ];
        
        for (final pattern in imageUrlPatterns) {
          final match = pattern.firstMatch(html);
          if (match != null) {
            String imageUrl = match.group(1)!;
            // Decode URL if needed
            imageUrl = Uri.decodeFull(imageUrl);
            // Validate the extracted URL
            if (await _isValidImageUrl(imageUrl)) {
              return imageUrl;
            }
          }
        }
        
        // Try to find any HTTPS image URL as fallback
        final fallbackPattern = RegExp(r'(https://[^\s"<>]*\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\s"<>]*)?)', caseSensitive: false);
        final fallbackMatch = fallbackPattern.firstMatch(html);
        if (fallbackMatch != null) {
          String imageUrl = fallbackMatch.group(1)!;
          imageUrl = Uri.decodeFull(imageUrl);
          if (await _isValidImageUrl(imageUrl)) {
            return imageUrl;
          }
        }
      }
      
      // If no direct image URL found, return the Google URL
      return googleUrl;
      
    } catch (e) {
      print('Error extracting Google image URL: $e');
      return googleUrl;
    }
  }
  
  /// Validates if a URL points to an accessible image
  static Future<bool> _isValidImageUrl(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          validateStatus: (status) => status != null && status == 200,
        ),
      );
      
      final contentType = response.headers.value('content-type');
      return contentType != null && contentType.startsWith('image/');
    } catch (e) {
      return false;
    }
  }
  
  /// Batch expand multiple URLs with progress callback
  static Future<Map<String, String?>> expandUrls(
    List<String> urls, {
    Function(int completed, int total)? onProgress,
  }) async {
    final Map<String, String?> results = {};
    int completed = 0;
    
    // Process URLs in parallel batches to avoid overwhelming the server
    const batchSize = 3;
    
    for (int i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize).toList();
      
      final futures = batch.map((url) async {
        try {
          final expanded = await expandUrl(url);
          completed++;
          onProgress?.call(completed, urls.length);
          return MapEntry(url, expanded);
        } catch (e) {
          completed++;
          onProgress?.call(completed, urls.length);
          return MapEntry(url, null);
        }
      });
      
      final batchResults = await Future.wait(futures);
      
      for (final entry in batchResults) {
        results[entry.key] = entry.value;
      }
      
      // Small delay between batches to be respectful to servers
      if (i + batchSize < urls.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return results;
  }
  
  /// Check if a URL is a shortened URL that needs expansion
  static bool needsExpansion(String url) {
    final shortenedDomains = [
      'goo.gl',
      'images.app.goo.gl',
      'bit.ly',
      't.co',
      'tinyurl.com',
      'short.link',
      'is.gd',
      'ow.ly',
      'tiny.cc',
      'rb.gy',
    ];
    
    return shortenedDomains.any((domain) => url.contains(domain));
  }
  
  /// Test if a URL is accessible
  static Future<bool> testUrl(String url) async {
    _configureDio();
    
    try {
      final response = await _dio.head(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }
  
  /// Get detailed information about a URL
  static Future<Map<String, dynamic>> getUrlInfo(String url) async {
    _configureDio();
    
    try {
      final response = await _dio.head(
        url,
        options: Options(
          validateStatus: (status) => status != null,
        ),
      );
      
      return {
        'url': url,
        'statusCode': response.statusCode,
        'contentType': response.headers.value('content-type'),
        'contentLength': response.headers.value('content-length'),
        'isImage': response.headers.value('content-type')?.startsWith('image/') ?? false,
        'isAccessible': response.statusCode != null && response.statusCode! < 400,
      };
    } catch (e) {
      return {
        'url': url,
        'error': e.toString(),
        'isAccessible': false,
      };
    }
  }
  
  /// Dispose of the Dio instance
  static void dispose() {
    _dio.close();
  }
}
