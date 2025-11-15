import 'dart:io';

import 'package:checkdreamproperty/models/format_inr.dart';
import 'package:checkdreamproperty/models/youtube_helper.dart';
import 'package:checkdreamproperty/sharedwidget/reusable_text_form_field.dart';
import 'package:checkdreamproperty/sharedwidget/reusable_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddPropertyDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onPropertyAdded;
  final Map<String, dynamic>? existingProperty;
  final List<Map<String, dynamic>> properties;

  const AddPropertyDialog({
    super.key,
    required this.onPropertyAdded,
    this.existingProperty,
    required this.properties,
  });

  @override
  State<AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _headerController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _groundsController = TextEditingController();
  final _builtupAreaController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _waterTaxController = TextEditingController();
  final _propertyTaxController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _ageYearsController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _maintenanceChargesController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _numberOfBalconiesController = TextEditingController();
  final _contactPersonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _numberOfParkingController = TextEditingController();

  // Form values
  String _selectedType = 'Apartment';
  String _selectedLocation = 'Velachery';
  String _selectedCity = 'Chennai';
  bool _forRent = false;
  List<String> _imageUrls = [];
  List<String> _phoneNumbers = [''];
  List<String> _landmarks = [''];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _selectedPurpose = 'For Sale';
  String _selectedPropertyStatus = 'none';
  String _selectedFurnishingStatus = 'none';
  String _selectedOwnerType = 'none';
  bool _negotiablePrice = false;
  bool _parkingAvailable = false;
  bool _balconyAvailable = false;
  bool _urgentSale = false;

  // New dropdown options
  final List<String> _purposeOptions = ['For Sale', 'For Rent'];
  final List<String> _propertyStatusOptions = [
    'New',
    'Resale',
    'Under Construction',
    'none'
  ];
  final List<String> _furnishingStatusOptions = [
    'Unfurnished',
    'Semi-Furnished',
    'Fully-Furnished',
    'none'
  ];
  final List<String> _ownerTypeOptions = ['Owner', 'Agent', 'Builder', 'none'];

  final List<String> _propertyTypes = [
    'Apartment',
    'Villa',
    'Plot',
    'Commercial',
    "Apartment / Flat",
    "Independent House / Villa",
    "Plot / Land",
    "Residential Building (Multi-Unit)",
    "Commercial Property",
    "Farm Land / Agriculture"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProperty != null) {
      _populateExistingData();
    }
  }

  void _populateExistingData() {
    final property = widget.existingProperty!;
    _headerController.text = property['header'] ?? '';
    _titleController.text = property['title'] ?? '';
    _selectedType = property['type'] ?? 'Apartment';
    _selectedLocation = property['location'] ?? 'Velachery';
    _selectedCity = property['city'] ?? 'Chennai';
    _priceController.text = property['price']?.toString() ?? '';
    _squareFeetController.text = property['squareFeet']?.toString() ?? '';
    _groundsController.text = property['grounds']?.toString() ?? '';
    _builtupAreaController.text = property['builtupArea']?.toString() ?? '';
    _mapLinkController.text = property['mapLink'] ?? '';
    _waterTaxController.text = property['waterTax']?.toString() ?? '';
    _propertyTaxController.text = property['propertyTax']?.toString() ?? '';
    _bedroomsController.text = property['bedrooms']?.toString() ?? '';
    _bathroomsController.text = property['bathrooms']?.toString() ?? '';
    _ageYearsController.text = property['ageYears']?.toString() ?? '';
    _forRent = property['forRent'] ?? false;
    _rentAmountController.text = property['rentAmount']?.toString() ?? '';
    _whatsappController.text = property['contact']?['whatsapp'] ?? '';
    _imageUrls = List<String>.from(property['images'] ?? []);
    _selectedPurpose = property['purpose'] ?? 'For Sale';
    _selectedPropertyStatus = property['propertyStatus'] ?? 'Resale';
    _selectedFurnishingStatus = property['furnishingStatus'] ?? 'Unfurnished';
    _selectedOwnerType = property['ownerType'] ?? 'Owner';
    _negotiablePrice = property['negotiablePrice'] ?? false;
    _parkingAvailable = property['parkingAvailable'] ?? false;
    _balconyAvailable = property['balconyAvailable'] ?? false;
    _urgentSale = property['urgentSale'] ?? false;

    _maintenanceChargesController.text =
        property['maintenanceCharges']?.toString() ?? '';
    _depositAmountController.text = property['depositAmount']?.toString() ?? '';
    _floorNumberController.text = property['floorNumber']?.toString() ?? '';
    _totalFloorsController.text = property['totalFloors']?.toString() ?? '';
    _numberOfBalconiesController.text =
        property['numberOfBalconies']?.toString() ?? '';
    _numberOfParkingController.text =
        property['numberOfParking']?.toString() ?? '';
    _contactPersonNameController.text = property['contactPersonName'] ?? '';
    _descriptionController.text = property['description'] ?? '';

    // Handle multiple phone numbers
    if (property['contact']?['phoneNumbers'] != null) {
      _phoneNumbers = List<String>.from(property['contact']['phoneNumbers']);
    } else if (property['contact']?['phone'] != null) {
      _phoneNumbers = [property['contact']['phone']];
    }

    // Handle multiple landmarks
    if (property['landmarks'] != null) {
      _landmarks = List<String>.from(property['landmarks']);
    } else if (property['landmark'] != null) {
      _landmarks = [property['landmark']];
    }

    final existingImages = List<String>.from(property['images'] ?? []);
    _imageUrls = List<String>.from(existingImages);
    _localImageFiles =
        List.generate(existingImages.length, (index) => File(''));
    _isImageUploaded = List.generate(existingImages.length, (index) => true);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _squareFeetController.dispose();
    _groundsController.dispose();
    _builtupAreaController.dispose();
    _mapLinkController.dispose();
    _waterTaxController.dispose();
    _propertyTaxController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _ageYearsController.dispose();
    _rentAmountController.dispose();
    _whatsappController.dispose();
    _imageUrlController.dispose();
    _scrollController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _maintenanceChargesController.dispose();
    _depositAmountController.dispose();
    _floorNumberController.dispose();
    _totalFloorsController.dispose();
    _numberOfBalconiesController.dispose();
    _contactPersonNameController.dispose();
    _descriptionController.dispose();
    _numberOfParkingController.dispose();
    super.dispose();
  }

  List<File> _localImageFiles =
      []; // Add this to store local files before upload
  List<bool> _isImageUploaded = [];

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        print('Image file does not exist');
        return null;
      }

      // Compress image before upload
      final compressedFile = await _compressImage(imageFile);
      if (compressedFile == null) {
        print('Failed to compress image');
        return null;
      }

      // Generate unique filename
      final fileExtension = path.extension(compressedFile.path).toLowerCase();
      final fileName =
          'property_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'property_images/$fileName';

      // Upload compressed file using Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      final uploadTask = await storageRef.putFile(
        compressedFile,
        SettableMetadata(contentType: _getContentType(fileExtension)),
      );

      // Clean up compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      // Get download URL
      final imageUrl = await uploadTask.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      // More specific error handling
      if (e.toString().contains('already exists')) {
        print('File already exists, generating new name...');
        // Retry with a different name
        return _uploadImageWithRetry(imageFile);
      } else if (e.toString().contains('permission denied')) {
        print('Permission denied. Please check your Firebase Storage rules.');
        return null;
      }

      print('Upload error: $e');
      return null;
    }
  }

// Add this new method for image compression:
  Future<File?> _compressImage(File originalFile) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path,
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Get original file size
      final originalSize = await originalFile.length();

      // Skip compression if file is already small (less than 500KB)
      if (originalSize < 500 * 1024) {
        return originalFile;
      }

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 80, // Adjust quality (0-100)
        minWidth: 1920, // Maximum width
        minHeight: 1080, // Maximum height
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        // final compressedSize = await File(compressedFile.path).length();
        return File(compressedFile.path);
      }

      return originalFile; // Return original if compression failed
    } catch (e) {
      return originalFile; // Return original if compression failed
    }
  }

  String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> _uploadImageWithRetry(File imageFile,
      [int retryCount = 0]) async {
    if (retryCount >= 3) {
      return null;
    }

    try {
      // Wait a bit before retry
      await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));

      // Compress image
      final compressedFile = await _compressImage(imageFile);
      if (compressedFile == null) {
        return null;
      }

      // Generate unique filename with timestamp and random number
      final fileExtension = path.extension(compressedFile.path).toLowerCase();
      final fileName =
          'property_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}$fileExtension';
      final filePath = 'property_images/$fileName';

      // Upload compressed file using Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      final uploadTask = await storageRef.putFile(
        compressedFile,
        SettableMetadata(contentType: _getContentType(fileExtension)),
      );

      // Clean up compressed file if different from original
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      // Get download URL
      final imageUrl = await uploadTask.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      if (e.toString().contains('The resource already exists')) {
        // Retry with different name
        return _uploadImageWithRetry(imageFile, retryCount + 1);
      }
      print('Retry failed: $e');
      return null;
    }
  }

// Updated _pickImageFile method with better compression options:
  // Future<void> _pickImageFile(ImageSource source) async {
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: source,
  //       maxWidth: 2048, // Increased for better quality before compression
  //       maxHeight: 2048,
  //       imageQuality: 90, // Higher quality since we'll compress later
  //     );

  //     if (image != null) {
  //       final File imageFile = File(image.path);

  //       // Check if file exists
  //       if (!await imageFile.exists()) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Selected image file not found')),
  //           );
  //         }
  //         return;
  //       }

  //       // Check file size (limit to 10MB before compression)
  //       final fileSize = await imageFile.length();
  //       if (fileSize > 10 * 1024 * 1024) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //                 content: Text('Image size should be less than 10MB')),
  //           );
  //         }
  //         return;
  //       }

  //       // Check file type
  //       final String fileExtension = path.extension(image.path).toLowerCase();
  //       if (!['.jpg', '.jpeg', '.png', '.webp'].contains(fileExtension)) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //                 content: Text(
  //                     'Please select a valid image file (JPG, PNG, WebP)')),
  //           );
  //         }
  //         return;
  //       }

  //       // Add local file to list immediately for preview
  //       setState(() {
  //         _localImageFiles.add(imageFile);
  //         _imageUrls.add(''); // Placeholder for URL
  //         _isImageUploaded.add(false); // Mark as not uploaded yet
  //       });

  //       // Upload in background
  //       _uploadImageInBackground(_localImageFiles.length - 1);
  //     }
  //   } catch (e) {
  //     print('Error picking image: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error picking image: $e')),
  //       );
  //     }
  //   }
  // }


  
// Replace your existing _pickImageFile method with this:
Future<void> _pickImageFile(ImageSource source) async {
  try {
    if (source == ImageSource.gallery) {
      // For gallery, allow multiple image selection
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        for (final XFile image in images) {
          await _processSelectedImage(image);
        }
      }
    } else {
      // For camera, single image selection
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    }
  } catch (e) {
    print('Error picking image: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
}

// Add this new method to process individual images:
Future<void> _processSelectedImage(XFile image) async {
  try {
    final File imageFile = File(image.path);

    // Check if file exists
    if (!await imageFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image file not found')),
        );
      }
      return;
    }

    // Check file size (limit to 10MB before compression)
    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size should be less than 10MB')
          ),
        );
      }
      return;
    }

    // Check file type
    final String fileExtension = path.extension(image.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(fileExtension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid image file (JPG, PNG, WebP)')
          ),
        );
      }
      return;
    }

    // Add local file to list immediately for preview
    setState(() {
      _localImageFiles.add(imageFile);
      _imageUrls.add(''); // Placeholder for URL
      _isImageUploaded.add(false); // Mark as not uploaded yet
    });

    // Upload in background
    _uploadImageInBackground(_localImageFiles.length - 1);
  } catch (e) {
    print('Error processing image: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }
}

// Updated background upload method:
  Future<void> _uploadImageInBackground(int index) async {
    try {
      setState(() {
        _isUploading = true;
      });

      String? imageUrl = await _uploadImage(_localImageFiles[index]);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _imageUrls[index] = imageUrl;
          _isImageUploaded[index] = true;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image compressed and uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Remove the failed upload from lists
        setState(() {
          _imageUrls.removeAt(index);
          _localImageFiles.removeAt(index);
          _isImageUploaded.removeAt(index);
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in background upload: $e');

      // Remove the failed upload from lists
      setState(() {
        if (index < _imageUrls.length) {
          _imageUrls.removeAt(index);
          _localImageFiles.removeAt(index);
          _isImageUploaded.removeAt(index);
        }
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addImageUrl() {
    if (_imageUrlController.text.isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlController.text);
        _localImageFiles.add(File('')); // Empty file for URL-based images
        _isImageUploaded.add(true); // URL images are considered "uploaded"
        _imageUrlController.clear();
      });
    }
  }

// Updated _removeImageUrl method
  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
      _localImageFiles.removeAt(index);
      _isImageUploaded.removeAt(index);
    });
  }

// Replace the _buildImageWidget method in AddPropertyDialog:
  // Widget _buildImageWidget(int index) {
  //   const double imageSize = 100;

  //   // If it's a local file (not uploaded yet), show from file
  //   if (!_isImageUploaded[index] && _localImageFiles[index].path.isNotEmpty) {
  //     return Image.file(
  //       _localImageFiles[index],
  //       width: imageSize,
  //       height: imageSize,
  //       fit: BoxFit.cover,
  //       errorBuilder: (context, error, stackTrace) {
  //         return Container(
  //           width: imageSize,
  //           height: imageSize,
  //           color: Colors.grey[300],
  //           child: const Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.error, color: Colors.red),
  //                 Text("Error", style: TextStyle(fontSize: 12)),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   }

  //   // If it's uploaded or a URL, show from network
  //   if (_imageUrls[index].isNotEmpty) {
  //     final url = _imageUrls[index];

  //     // Check if it's a YouTube URL
  //     if (YouTubeHelper.isYouTubeUrl(url)) {
  //       final videoId = YouTubeHelper.extractVideoId(url);
  //       if (videoId != null) {
  //         return Stack(
  //           children: [
  //             Image.network(
  //               YouTubeHelper.getThumbnailUrl(videoId),
  //               width: imageSize,
  //               height: imageSize,
  //               fit: BoxFit.cover,
  //               loadingBuilder: (context, child, loadingProgress) {
  //                 if (loadingProgress == null) return child;
  //                 return Container(
  //                   width: imageSize,
  //                   height: imageSize,
  //                   color: Colors.grey[300],
  //                   child: Center(
  //                     child: CircularProgressIndicator(
  //                       value: loadingProgress.expectedTotalBytes != null
  //                           ? loadingProgress.cumulativeBytesLoaded /
  //                               loadingProgress.expectedTotalBytes!
  //                           : null,
  //                     ),
  //                   ),
  //                 );
  //               },
  //               errorBuilder: (context, error, stackTrace) {
  //                 return Container(
  //                   width: imageSize,
  //                   height: imageSize,
  //                   color: Colors.grey[300],
  //                   child: const Center(
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Icon(Icons.error, color: Colors.red),
  //                         Text("Error", style: TextStyle(fontSize: 12)),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //             // YouTube play button overlay
  //             Center(
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   color: Colors.red.withOpacity(0.8),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 padding: const EdgeInsets.all(8),
  //                 child: const Icon(
  //                   Icons.play_arrow,
  //                   color: Colors.white,
  //                   size: 16,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         );
  //       }
  //     }

  //     // Regular image
  //     return Image.network(
  //       url,
  //       width: imageSize,
  //       height: imageSize,
  //       fit: BoxFit.cover,
  //       loadingBuilder: (context, child, loadingProgress) {
  //         if (loadingProgress == null) return child;
  //         return Container(
  //           width: imageSize,
  //           height: imageSize,
  //           color: Colors.grey[300],
  //           child: Center(
  //             child: CircularProgressIndicator(
  //               value: loadingProgress.expectedTotalBytes != null
  //                   ? loadingProgress.cumulativeBytesLoaded /
  //                       loadingProgress.expectedTotalBytes!
  //                   : null,
  //             ),
  //           ),
  //         );
  //       },
  //       errorBuilder: (context, error, stackTrace) {
  //         return Container(
  //           width: imageSize,
  //           height: imageSize,
  //           color: Colors.grey[300],
  //           child: const Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.error, color: Colors.red),
  //                 Text("Error", style: TextStyle(fontSize: 12)),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   }

  //   // Fallback
  //   return Container(
  //     width: imageSize,
  //     height: imageSize,
  //     color: Colors.grey[300],
  //     child: const Center(
  //       child: Icon(Icons.image, color: Colors.grey),
  //     ),
  //   );
  // }

  Widget _buildImageWidget(int index) {
    final url = _imageUrls[index];
    final isYouTube = YouTubeHelper.isYouTubeUrl(url);

    if (isYouTube) {
      final videoId = YouTubeHelper.extractVideoId(url);
      if (videoId != null) {
        return Stack(
          children: [
            Image.network(
              YouTubeHelper.getThumbnailUrl(videoId),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildYouTubePreviewError(), // YouTube-specific error for preview
            ),
            // Play button overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return _buildYouTubePreviewError();
      }
    } else {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }

// New method for YouTube preview error in upload section
  Widget _buildYouTubePreviewError() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.youtube,
            size: 24,
            color: Colors.red,
          ),
          const SizedBox(height: 4),
          Text(
            'Video',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// Replace the _buildImageUploadSection method in AddPropertyDialog:
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _imageUrlController,
                label: 'Image/Video URL',
                hint: 'https://example.com/image.jpg or YouTube URL',
                prefixIcon: Icons.link,
              ),
            ),
            const SizedBox(width: 8),
            ReusableIconButton(
              onPressed: _addImageUrl,
              icon: Icons.add_circle,
              iconColor: Theme.of(context).primaryColor,
              iconSize: 22,
            ),
          ],
        ),

        if (_isUploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Uploading image...'),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Updated image preview with YouTube support
        if (_imageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final isYouTube = YouTubeHelper.isYouTubeUrl(_imageUrls[index]);

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(index),
                      ),

                      // YouTube indicator
                      if (isYouTube)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIDEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Upload status indicator
                      if (!_isImageUploaded[index])
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),

                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImageUrl(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // Upload buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickImageFile(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Multi-Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickImageFile(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Note: You can add images, YouTube videos, or other media URLs',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _addPhoneNumber() {
    setState(() {
      _phoneNumbers.add('');
    });
  }

  void _removePhoneNumber(int index) {
    if (_phoneNumbers.length > 1) {
      setState(() {
        _phoneNumbers.removeAt(index);
      });
    }
  }

  void _addLandmark() {
    setState(() {
      _landmarks.add('');
    });
  }

  void _removeLandmark(int index) {
    if (_landmarks.length > 1) {
      setState(() {
        _landmarks.removeAt(index);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final validPhoneNumbers =
          _phoneNumbers.where((phone) => phone.trim().isNotEmpty).map((phone) {
        String cleanPhone = phone.trim();
        // Ensure it's a 10-digit number and add +91 prefix
        if (cleanPhone.length == 10 &&
            RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanPhone)) {
          return '+91$cleanPhone';
        }
        return cleanPhone.startsWith('+91') ? cleanPhone : '+91$cleanPhone';
      }).toList();

      final finalImageUrls = <String>[];
      for (int i = 0; i < _imageUrls.length; i++) {
        if (_isImageUploaded[i] && _imageUrls[i].isNotEmpty) {
          finalImageUrls.add(_imageUrls[i]);
        }
      }

      final validLandmarks =
          _landmarks.where((landmark) => landmark.trim().isNotEmpty).toList();

      // Process WhatsApp number - ensure it's 10 digits and add +91
      String whatsappNumber = _whatsappController.text.trim();
      if (whatsappNumber.isNotEmpty) {
        if (whatsappNumber.length == 10 &&
            RegExp(r'^[6-9][0-9]{9}$').hasMatch(whatsappNumber)) {
          whatsappNumber = '+91$whatsappNumber';
        } else if (!whatsappNumber.startsWith('+91')) {
          whatsappNumber = '+91$whatsappNumber';
        }
      }
      print('WhatsApp number: $finalImageUrls');

      final propertyData = {
        'header': _headerController.text,
        'title': _titleController.text,
        'type': _selectedType,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text.trim()
            : _selectedLocation,
        'city': _cityController.text.isNotEmpty
            ? _cityController.text.trim()
            : _selectedCity,
        'price': double.tryParse(_priceController.text) ?? 0,
        'squareFeet': double.tryParse(_squareFeetController.text) ?? 0,
        'grounds': double.tryParse(_groundsController.text) ?? 0,
        'builtupArea': double.tryParse(_builtupAreaController.text) ?? 0,
        'landmarks': validLandmarks,
        'mapLink': _mapLinkController.text.trim(),
        'waterTax': double.tryParse(_waterTaxController.text) ?? 0,
        'propertyTax': double.tryParse(_propertyTaxController.text) ?? 0,
        'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
        'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
        'ageYears': int.tryParse(_ageYearsController.text) ?? 0,
        'forRent': _forRent,
        'rentAmount': double.tryParse(_rentAmountController.text) ?? 0,
        'images': finalImageUrls,
        'contact': {
          // 'phoneNumbers': validPhoneNumbers,
          'phone': validPhoneNumbers.isNotEmpty ? validPhoneNumbers.first : '',
          'whatsapp': whatsappNumber,
        },
        'purpose': _selectedPurpose,
        'propertyStatus': _selectedPropertyStatus,
        'furnishingStatus': _selectedFurnishingStatus,
        'ownerType': _selectedOwnerType,
        'negotiablePrice': _negotiablePrice,
        'parkingAvailable': _parkingAvailable,
        'balconyAvailable': _balconyAvailable,
        'urgentSale': _urgentSale,
        'maintenanceCharges':
            double.tryParse(_maintenanceChargesController.text) ?? 0,
        'depositAmount': double.tryParse(_depositAmountController.text) ?? 0,
        'floorNumber': int.tryParse(_floorNumberController.text) ?? 0,
        'totalFloors': int.tryParse(_totalFloorsController.text) ?? 0,
        'numberOfBalconies':
            int.tryParse(_numberOfBalconiesController.text) ?? 0,
        'numberOfParking': int.tryParse(_numberOfParkingController.text) ?? 0,
        'contactPersonName': _contactPersonNameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      widget.onPropertyAdded(propertyData);
      Navigator.of(context).pop();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ReusableTextFormField(
        label: label,
        hintText: hint,
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        validator: validator,
        onChanged: onChanged,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      ),
    );
  }

  Widget _buildMultiplePhoneNumbers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Numbers',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_phoneNumbers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _phoneNumbers[index],
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (value) => _phoneNumbers[index] = value,
                    validator: (value) {
                      if (index == 0 && (value?.isEmpty == true)) {
                        return 'At least one phone number is required';
                      }
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 10) {
                          return 'Enter 10-digit number';
                        }
                        if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                          return 'Invalid Indian mobile number';
                        }
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      prefixIcon: const Icon(Icons.phone, size: 20),
                      prefixText: '+91 ',
                      prefixStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      counterText: '', // Hide character counter
                    ),
                  ),
                ),
                if (_phoneNumbers.length > 1)
                  ReusableIconButton(
                    onPressed: () => _removePhoneNumber(index),
                    icon: Icons.remove_circle,
                    iconColor: Colors.red,
                    iconSize: 24,
                  ),
                if (index ==
                    _phoneNumbers.length -
                        1) // Only show add button on last item
                  ReusableIconButton(
                    onPressed: _addPhoneNumber,
                    icon: Icons.add_circle,
                    iconColor: Theme.of(context).primaryColor,
                    iconSize: 24,
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMultipleLandmarks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_landmarks.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: ReusableTextFormField(
                    initialValue: _landmarks[index],
                    hintText: 'Landmark',
                    onChanged: (value) => _landmarks[index] = value,
                    prefixIcon: const Icon(Icons.location_on, size: 20),
                  ),
                ),
                if (_landmarks.length > 1)
                  ReusableIconButton(
                    onPressed: () => _removeLandmark(index),
                    icon: Icons.remove_circle,
                    iconColor: Colors.red,
                    iconSize: 20,
                  ),
                ReusableIconButton(
                  onPressed: _addLandmark,
                  icon: Icons.add_circle,
                  iconColor: Theme.of(context).primaryColor,
                  iconSize: 20,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // Updated image picker method

  List<String> _getUniqueValues(String fieldName) {
    return widget.properties
        .map((p) => p[fieldName]?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty && value != 'N/A')
        .toSet() // This removes duplicates
        .toList()
      ..sort(); // Sort alphabetically
  }

  List<String> _getSuggestions(String fieldName, String pattern) {
    final values = _getUniqueValues(fieldName);
    if (pattern.isEmpty) {
      return values.take(10).toList(); // Limit to 10 suggestions
    }
    return values
        .where((value) => value.toLowerCase().contains(pattern.toLowerCase()))
        .take(10) // Limit suggestions
        .toList();
  }

  Widget _buildWhatsAppTextField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _whatsappController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            if (value.length != 10) {
              return 'Please enter a valid 10-digit mobile number';
            }
            if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
              return 'Please enter a valid Indian mobile number';
            }
          }
          return null;
        },
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: 'WhatsApp Number',
          hintText: '9876543210',
          prefixIcon: const Icon(FontAwesomeIcons.whatsapp,
              size: 20, color: Colors.green),
          prefixText: '+91 ',
          prefixStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '', // Hide character counter
          helperText: 'Enter 10-digit mobile number',
          helperStyle:
              GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      insetPadding: const EdgeInsets.all(0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingProperty != null
                        ? 'Edit Property'
                        : 'Add New Property',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _titleController,
                              label: 'Property Title',
                              hint: 'e.g., Premium Villa in Velachery',
                              validator: (value) => value?.isEmpty == true
                                  ? 'Title is required'
                                  : null,
                            ),

                            _buildDropdownField(
                              label: 'Property Type',
                              value: _selectedType,
                              items: _propertyTypes,
                              onChanged: (value) =>
                                  setState(() => _selectedType = value!),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TypeAheadField<String>(
                                controller: _locationController,
                                suggestionsCallback: (pattern) {
                                  final suggestions =
                                      _getSuggestions('location', pattern);
                                  return suggestions.toSet().toList()..sort();
                                },
                                itemBuilder: (context, suggestion) => ListTile(
                                  leading:
                                      const Icon(Icons.location_on, size: 16),
                                  title: Text(
                                    suggestion,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                                onSelected: (suggestion) =>
                                    _locationController.text = suggestion,
                                builder: (context, controller, focusNode) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Location is required'
                                        : null,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Location/Area *',
                                      hintText: 'e.g., Velachery, Anna Nagar',
                                      prefixIcon: const Icon(Icons.location_on,
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                  );
                                },
                                emptyBuilder: (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                      'No locations found. Type to add new location.'),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TypeAheadField<String>(
                                controller: _cityController,
                                suggestionsCallback: (pattern) {
                                  final suggestions =
                                      _getSuggestions('city', pattern);
                                  // Additional manual filtering to ensure no duplicates
                                  return suggestions.toSet().toList()..sort();
                                },
                                itemBuilder: (context, suggestion) => ListTile(
                                  leading:
                                      const Icon(Icons.location_city, size: 16),
                                  title: Text(
                                    suggestion,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                                onSelected: (suggestion) =>
                                    _cityController.text = suggestion,
                                builder: (context, controller, focusNode) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    validator: (value) => value?.isEmpty == true
                                        ? 'City is required'
                                        : null,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'City *',
                                      hintText: 'e.g., Chennai, Coimbatore',
                                      prefixIcon: const Icon(
                                          Icons.location_city,
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                  );
                                },
                                emptyBuilder: (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                      'No cities found. Type to add new city.'),
                                ),
                              ),
                            ),

                            _buildMultipleLandmarks(),

                            _buildTextField(
                              controller: _mapLinkController,
                              label: 'Google Maps Link',
                              hint: 'https://maps.google.com/?q=...',
                            ),

                            _buildTextField(
                              controller: _priceController,
                              label: 'Price (₹)',
                              hint: '8500000₹',
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true
                                  ? 'Price is required'
                                  : null,
                              onChanged: (value) {
                                setState(
                                    () {}); // Trigger rebuild to update the display text
                              },
                            ),
                            if (_priceController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 4),
                                child: Text(
                                  Inr.formatIndianNumber(_priceController.text),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            _buildTextField(
                              controller: _rentAmountController,
                              label: 'Monthly Rent (₹)',
                              hint: '25000',
                              keyboardType: TextInputType.number,
                            ),
                            if (_rentAmountController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 4),
                                child: Text(
                                  Inr.formatIndianNumber(
                                      _rentAmountController.text),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            // Purpose dropdown
                            _buildDropdownField(
                              label: 'Purpose *',
                              value: _selectedPurpose,
                              items: _purposeOptions,
                              onChanged: (value) => setState(() {
                                _selectedPurpose = value!;
                                _forRent = value == 'For Rent';
                              }),
                            ),

                            // Property Status dropdown
                            _buildDropdownField(
                              label: 'Property Status',
                              value: _selectedPropertyStatus,
                              items: _propertyStatusOptions,
                              onChanged: (value) => setState(
                                  () => _selectedPropertyStatus = value!),
                            ),

                            // Urgent Sale toggle
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.priority_high,
                                      size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Urgent Sale',
                                      style: GoogleFonts.poppins(fontSize: 14)),
                                  const Spacer(),
                                  Switch(
                                    value: _urgentSale,
                                    onChanged: (value) =>
                                        setState(() => _urgentSale = value),
                                    activeColor: Colors.red,
                                  ),
                                ],
                              ),
                            ),

                            // Negotiable Price toggle
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.handshake, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Negotiable Price',
                                      style: GoogleFonts.poppins(fontSize: 14)),
                                  const Spacer(),
                                  Switch(
                                    value: _negotiablePrice,
                                    onChanged: (value) => setState(
                                        () => _negotiablePrice = value),
                                  ),
                                ],
                              ),
                            ),

                            // Maintenance Charges
                            _buildTextField(
                              controller: _maintenanceChargesController,
                              label: 'Maintenance Charges (₹/month)',
                              hint: '2500',
                              prefixIcon: Icons.build,
                            ),

                            // Deposit Amount (show only for rentals)
                            if (_selectedPurpose == 'For Rent')
                              _buildTextField(
                                controller: _depositAmountController,
                                label: 'Deposit Amount (₹)',
                                hint: '50000',
                                prefixIcon: Icons.account_balance_wallet,
                              ),

                            // Floor Number and Total Floors
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _floorNumberController,
                                    label: 'Floor Number',
                                    hint: '3',
                                    prefixIcon: Icons.layers,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _totalFloorsController,
                                    label: 'Total Floors',
                                    hint: '10',
                                    prefixIcon: Icons.business,
                                  ),
                                ),
                              ],
                            ),

                            // Parking Availability
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_parking, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Parking Available',
                                          style: GoogleFonts.poppins(
                                              fontSize: 14)),
                                      const Spacer(),
                                      Switch(
                                        value: _parkingAvailable,
                                        onChanged: (value) => setState(
                                            () => _parkingAvailable = value),
                                      ),
                                    ],
                                  ),
                                  if (_parkingAvailable)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _buildTextField(
                                        controller: _numberOfParkingController,
                                        label: 'Number of Parking Spaces',
                                        hint: '2',
                                        prefixIcon: Icons.directions_car,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Balcony Availability
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.balcony, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Balcony Available',
                                          style: GoogleFonts.poppins(
                                              fontSize: 14)),
                                      const Spacer(),
                                      Switch(
                                        value: _balconyAvailable,
                                        onChanged: (value) => setState(
                                            () => _balconyAvailable = value),
                                      ),
                                    ],
                                  ),
                                  if (_balconyAvailable)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _buildTextField(
                                        controller:
                                            _numberOfBalconiesController,
                                        label: 'Number of Balconies',
                                        hint: '1',
                                        prefixIcon: Icons.balcony,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Furnishing Status dropdown
                            _buildDropdownField(
                              label: 'Furnishing Status',
                              value: _selectedFurnishingStatus,
                              items: _furnishingStatusOptions,
                              onChanged: (value) => setState(
                                  () => _selectedFurnishingStatus = value!),
                            ),

                            // Owner Type dropdown
                            _buildDropdownField(
                              label: 'Owner Type',
                              value: _selectedOwnerType,
                              items: _ownerTypeOptions,
                              onChanged: (value) =>
                                  setState(() => _selectedOwnerType = value!),
                            ),

                            // Contact Person Name
                            _buildTextField(
                              controller: _contactPersonNameController,
                              label: 'Contact Person Name',
                              hint: 'Mr. John Doe',
                              prefixIcon: Icons.person,
                            ),

                            // Description
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                maxLength: 500,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Property Description',
                                  hintText:
                                      'Describe your property features, nearby amenities, etc.',
                                  prefixIcon:
                                      const Icon(Icons.description, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ),

                            _buildTextField(
                              controller: _waterTaxController,
                              label: 'Water Tax (₹)',
                              hint: '5000',
                            ),

                            _buildTextField(
                              controller: _propertyTaxController,
                              label: 'Property Tax (₹)',
                              hint: '15000',
                            ),

                            _buildTextField(
                              controller: _squareFeetController,
                              label: 'Square Feet',
                              hint: '2400',
                              keyboardType: TextInputType.number,
                            ),

                            _buildTextField(
                              controller: _builtupAreaController,
                              label: 'Built-up Area',
                              hint: '2200',
                              keyboardType: TextInputType.number,
                            ),

                            _buildTextField(
                              controller: _groundsController,
                              label: 'Grounds',
                              hint: '2.5',
                            ),

                            _buildTextField(
                              controller: _bedroomsController,
                              label: 'Bedrooms',
                              hint: '3',
                            ),

                            _buildTextField(
                              controller: _bathroomsController,
                              label: 'Bathrooms',
                              hint: '3',
                            ),

                            _buildTextField(
                              controller: _ageYearsController,
                              label: 'How old is the property? (years)',
                              hint: '2',
                            ),

                            // Multiple Phone Numbers
                            _buildMultiplePhoneNumbers(),

                            _buildWhatsAppTextField(),

                            // Property Images with enhanced upload options
                            _buildImageUploadSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingProperty != null
                            ? 'Update Property'
                            : 'Add Property',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final currentValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
       
        isExpanded: true,
        value: currentValue,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
