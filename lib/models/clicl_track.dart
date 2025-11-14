import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:universal_html/html.dart' as html;

class ClickTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionIdKey = 'user_session_id';
  static const String _fingerprintKey = 'user_fingerprint';
  
  // Environment flag - set this to false in production
  static const bool _isDevelopment = kDebugMode;
  
  String? _sessionId;
  String? _userFingerprint;
  bool _initialized = false;

  // Initialize the tracking service
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Get or create session ID
    _sessionId = prefs.getString(_sessionIdKey);
    if (_sessionId == null) {
      _sessionId = _generateSessionId();
      await prefs.setString(_sessionIdKey, _sessionId!);
    }
    
    // Get or create user fingerprint
    _userFingerprint = prefs.getString(_fingerprintKey);
    if (_userFingerprint == null) {
      _userFingerprint = await _generateUserFingerprint();
      await prefs.setString(_fingerprintKey, _userFingerprint!);
    }
    
    _initialized = true;
  }

  // Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'session_${md5.convert(utf8.encode(random)).toString().substring(0, 16)}';
  }

  // Generate user fingerprint based on device/browser characteristics
  Future<String> _generateUserFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String fingerprint = '';
    
    try {
      if (kIsWeb) {
        // Web-specific fingerprinting
        final webBrowserInfo = await deviceInfo.webBrowserInfo;
        final screen = html.window.screen;
        final navigator = html.window.navigator;
        
        fingerprint = [
          webBrowserInfo.userAgent ?? '',
          webBrowserInfo.language ?? '',
          webBrowserInfo.platform ?? '',
          screen?.width.toString() ?? '',
          screen?.height.toString() ?? '',
          navigator.hardwareConcurrency?.toString() ?? '',
          DateTime.now().timeZoneOffset.inHours.toString(),
        ].join('|');
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        fingerprint = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.version.release,
          androidInfo.id,
        ].join('|');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        fingerprint = [
          iosInfo.name,
          iosInfo.model,
          iosInfo.systemVersion,
          iosInfo.identifierForVendor,
        ].join('|');
      }
      
      // Hash the fingerprint for privacy
      return md5.convert(utf8.encode(fingerprint)).toString();
    } catch (e) {
      print('Error generating fingerprint: $e');
      // Fallback to timestamp-based ID
      return _generateSessionId();
    }
  }

  // Get device type
  String _getDeviceType() {
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      if (userAgent.contains('mobile')) return 'mobile';
      if (userAgent.contains('tablet')) return 'tablet';
      return 'desktop';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'mobile';
    }
    return 'desktop';
  }

  // Get browser name
  String _getBrowserName() {
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      if (userAgent.contains('chrome')) return 'Chrome';
      if (userAgent.contains('firefox')) return 'Firefox';
      if (userAgent.contains('safari')) return 'Safari';
      if (userAgent.contains('edge')) return 'Edge';
      return 'Unknown';
    }
    return 'App';
  }

  // Check if current user is a developer
  Future<bool> _isDeveloperClick() async {
    if (!_isDevelopment) return false; // In production, return false
    
    try {
      // Check against developer IP list
      if (kIsWeb) {
        // For web, you might need to get IP from your backend
        // This is a simplified check
        return true; // In development, mark as developer
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Main method to track property clicks
  Future<bool> trackPropertyClick({
    required String propertyId,
    String clickType = 'view',
    String? referrer,
  }) async {
    try {
      await initialize();

      final isDev = await _isDeveloperClick();

      final clickData = {
        'property_id': propertyId,
        'user_fingerprint': _userFingerprint,
        'session_id': _sessionId,
        'click_type': clickType,
        'user_agent': kIsWeb ? html.window.navigator.userAgent : Platform.operatingSystem,
        'device_type': _getDeviceType(),
        'browser_name': _getBrowserName(),
        'referrer': referrer ?? (kIsWeb ? html.document.referrer : null),
        'is_developer': isDev,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('property_clicks').add(clickData);

      print('Click tracked: Property $propertyId, Type: $clickType, IsDev: $isDev');
      return true;
    } catch (e) {
      print('Error tracking click: $e');
      return false;
    }
  }

  // Track different types of clicks
  Future<void> trackPropertyView(String propertyId) async {
    await trackPropertyClick(propertyId: propertyId, clickType: 'view');
  }

  Future<void> trackPhoneClick(String propertyId) async {
    await trackPropertyClick(propertyId: propertyId, clickType: 'phone');
  }

  Future<void> trackWhatsAppClick(String propertyId) async {
    await trackPropertyClick(propertyId: propertyId, clickType: 'whatsapp');
  }

  Future<void> trackMapClick(String propertyId) async {
    await trackPropertyClick(propertyId: propertyId, clickType: 'map');
  }

  Future<void> trackDetailsClick(String propertyId) async {
    await trackPropertyClick(propertyId: propertyId, clickType: 'details');
  }

  // Analytics methods
  Future<List<Map<String, dynamic>>> getMostClickedProperties({
    int limit = 10,
    bool excludeDeveloper = true,
  }) async {
    try {
      var query = _firestore.collection('property_clicks').orderBy('created_at', descending: true);

      if (excludeDeveloper) {
        query = query.where('is_developer', isEqualTo: false);
      }

      final response = await query.limit(limit).get();

      return response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting most clicked properties: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyClickStats(String propertyId) async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .where('property_id', isEqualTo: propertyId)
          .get();

      return response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting property stats: $e');
      return [];
    }
  }

  // Get click trends over time
  Future<List<Map<String, dynamic>>> getClickTrends({
    String? propertyId,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      var query = _firestore
          .collection('property_clicks')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('is_developer', isEqualTo: false);

      if (propertyId != null) {
        query = query.where('property_id', isEqualTo: propertyId);
      }

      final response = await query.orderBy('created_at').get();

      return response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting click trends: $e');
      return [];
    }
  }
}