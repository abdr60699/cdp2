import 'package:animate_do/animate_do.dart';
import 'package:checkdreamproperty/widgets/contact.dart';
import 'package:checkdreamproperty/appbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_property_dialog.dart';
import 'models/property_model.dart';
import 'property_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPropertyType = 'All Properties';
  final String _selectedLocation = 'All Locations';
  RangeValues _priceRange = const RangeValues(100000, 100000000);
  final PropertyService _propertyService = PropertyService();
  bool _isLoading = false;
  final List<Map<String, dynamic>> _properties = [];
  bool isMobile = false;

  // Replace _selectedAreas with _selectedCities and add _cities list
  List<String> _selectedLocations = ['All Locations'];
  List<String> _selectedCities = [];

  // Sample data - replace with your actual data
  List<String> _locations = ['All Locations'];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }


List<Map<String, dynamic>> get filteredProperties {

  
  List<Map<String, dynamic>> filtered = List.from(_properties);

  // Debug: Print each property's structure
  for (int i = 0; i < _properties.length; i++) {
    final property = _properties[i];
    print('\n📋 Property ${i + 1} (ID: ${property['id']}):');
    
    // Check if it's nested structure
    if (property.containsKey('property_data') && property['property_data'] is Map) {
      final propertyData = property['property_data'] as Map<String, dynamic>;
      print('  📦 Has nested property_data');
      print('  🏠 Title: ${propertyData['title']}');
      print('  🏙️ City: ${propertyData['city']}');
      print('  📍 Location: ${propertyData['location']}');
      print('  🏠 Type: ${propertyData['type']}');
      print('  💰 Price: ${propertyData['price']}');
      print('  🏠 For Rent: ${propertyData['forRent']}');
      print('  💰 Rent Amount: ${propertyData['rentAmount']}');
      print('  📅 Purpose: ${propertyData['purpose']}');
    } else {
      print('  📦 Flat structure (no property_data)');
      print('  🏠 Title: ${property['title']}');
      print('  🏙️ City: ${property['city']}');
      print('  📍 Location: ${property['location']}');
      print('  🏠 Type: ${property['type']}');
      print('  💰 Price: ${property['price']}');
      print('  🏠 For Rent: ${property['forRent']}');
    }
  }

  // Apply search filter - search across multiple fields
  if (_searchController.text.isNotEmpty) {
    print('\n🔎 Applying search filter...');
    final searchTerm = _searchController.text.toLowerCase();
    final beforeSearch = filtered.length;
    
    filtered = filtered.where((property) {
      Map<String, dynamic> propertyData = property;
      if (property.containsKey('property_data') && property['property_data'] is Map) {
        propertyData = property['property_data'] as Map<String, dynamic>;
      }
      
      final title = (propertyData['title'] ?? '').toString().toLowerCase();
      final city = (propertyData['city'] ?? '').toString().toLowerCase();
      final location = (propertyData['location'] ?? '').toString().toLowerCase();
      final landmarks = (propertyData['landmarks'] as List<dynamic>? ?? [])
          .map((l) => l.toString().toLowerCase())
          .join(' ');

      final matches = title.contains(searchTerm) ||
          city.contains(searchTerm) ||
          location.contains(searchTerm) ||
          landmarks.contains(searchTerm);
      
      if (!matches) {
        print('  ❌ Property ${property['id']} filtered out by search');
      }
      
      return matches;
    }).toList();
    
    print('  📊 After search filter: $beforeSearch -> ${filtered.length}');
  }

  // Apply location filter
  if (_selectedLocations.isNotEmpty && !_selectedLocations.contains('All Locations')) {
    print('\n📍 Applying location filter...');
    final beforeLocation = filtered.length;
    
    filtered = filtered.where((property) {
      Map<String, dynamic> propertyData = property;
      if (property.containsKey('property_data') && property['property_data'] is Map) {
        propertyData = property['property_data'] as Map<String, dynamic>;
      }
      
      final city = propertyData['city']?.toString() ?? '';
      final location = propertyData['location']?.toString() ?? '';

      final matches = _selectedLocations.any((selectedLocation) =>
          selectedLocation == city ||
          selectedLocation == location ||
          selectedLocation == '$location, $city');
      
      if (!matches) {
        print('  ❌ Property ${property['id']} filtered out by location (city: $city, location: $location)');
      }
      
      return matches;
    }).toList();
    
    print('  📊 After location filter: $beforeLocation -> ${filtered.length}');
  }

  // Apply city filter
  if (_selectedCities.isNotEmpty) {
    print('\n🏙️ Applying city filter...');
    final beforeCity = filtered.length;
    
    filtered = filtered.where((property) {
      Map<String, dynamic> propertyData = property;
      if (property.containsKey('property_data') && property['property_data'] is Map) {
        propertyData = property['property_data'] as Map<String, dynamic>;
      }
      
      final city = propertyData['city']?.toString() ?? '';
      final matches = _selectedCities.contains(city);
      
      if (!matches) {
        print('  ❌ Property ${property['id']} filtered out by city filter (city: $city)');
      }
      
      return matches;
    }).toList();
    
    print('  📊 After city filter: $beforeCity -> ${filtered.length}');
  }

  // Apply property type filter
  if (_selectedPropertyType != 'All Properties') {
    print('\n🏠 Applying property type filter ($_selectedPropertyType)...');
    final beforeType = filtered.length;
    
    if (_selectedPropertyType == 'Buy') {
      filtered = filtered.where((property) {
        Map<String, dynamic> propertyData = property;
        if (property.containsKey('property_data') && property['property_data'] is Map) {
          propertyData = property['property_data'] as Map<String, dynamic>;
        }
        
        final forRent = propertyData['forRent'];
        final matches = forRent != true;
        
        print('  🏠 Property ${property['id']}: forRent=$forRent, matches Buy filter=$matches');
        
        return matches;
      }).toList();
    } else if (_selectedPropertyType == 'Rent') {
      filtered = filtered.where((property) {
        Map<String, dynamic> propertyData = property;
        if (property.containsKey('property_data') && property['property_data'] is Map) {
          propertyData = property['property_data'] as Map<String, dynamic>;
        }
        
        final forRent = propertyData['forRent'];
        final matches = forRent == true;
        
        print('  🏠 Property ${property['id']}: forRent=$forRent, matches Rent filter=$matches');
        
        return matches;
      }).toList();
    } else if (_selectedPropertyType == 'New Project') {
      filtered = filtered.where((property) {
        final matches = _isNewProject(property);
        print('  🏠 Property ${property['id']}: matches New Project filter=$matches');
        return matches;
      }).toList();
    }
    
    print('  📊 After property type filter: $beforeType -> ${filtered.length}');
  }

  // Apply price filter
  print('\n💰 Applying price filter...');
  final beforePrice = filtered.length;
  
  filtered = filtered.where((property) {
    Map<String, dynamic> propertyData = property;
    if (property.containsKey('property_data') && property['property_data'] is Map) {
      propertyData = property['property_data'] as Map<String, dynamic>;
    }
    
    final forRent = propertyData['forRent'] == true;
    final price = forRent
        ? (propertyData['rentAmount'] ?? 0)
        : (propertyData['price'] ?? 0);
    
    final matches = price >= _priceRange.start && price <= _priceRange.end;
    
    print('  💰 Property ${property['id']}: forRent=$forRent, price=$price, range=${_priceRange.start}-${_priceRange.end}, matches=$matches');
    
    return matches;
  }).toList();
  
  
  return filtered;
}

// Also add debug to your _isNewProject method
bool _isNewProject(Map<String, dynamic> property) {
  print('\n🆕 Checking if property ${property['id']} is new project...');
  
  try {
    // Check the root level created_at first
    final createdDate = property['createdDate'] ??
        property['created_at'] ??
        property['dateCreated'];
    
    print('  📅 Root level date fields: createdDate=${property['createdDate']}, created_at=${property['created_at']}, dateCreated=${property['dateCreated']}');
    
    if (createdDate == null) {
      // If no date at root level, check inside property_data
      if (property.containsKey('property_data') && property['property_data'] is Map) {
        final propertyData = property['property_data'] as Map<String, dynamic>;
        final nestedCreatedDate = propertyData['createdDate'] ??
            propertyData['created_at'] ??
            propertyData['dateCreated'];
        
        print('  📅 Nested date fields: createdDate=${propertyData['createdDate']}, created_at=${propertyData['created_at']}, dateCreated=${propertyData['dateCreated']}');
        
        if (nestedCreatedDate == null) {
          print('  ❌ No date found in nested data');
          return false;
        }
        
        DateTime propertyDate;
        if (nestedCreatedDate is String) {
          propertyDate = DateTime.parse(nestedCreatedDate);
        } else if (nestedCreatedDate is DateTime) {
          propertyDate = nestedCreatedDate;
        } else {
          print('  ❌ Invalid date format in nested data');
          return false;
        }

        final now = DateTime.now();
        final oneMonthAgo = now.subtract(const Duration(days: 30));
        final isNew = propertyDate.isAfter(oneMonthAgo);
        
        print('  📅 Property date: $propertyDate, One month ago: $oneMonthAgo, Is new: $isNew');
        return isNew;
      }
      print('  ❌ No date found at root or nested level');
      return false;
    }

    DateTime propertyDate;
    if (createdDate is String) {
      propertyDate = DateTime.parse(createdDate);
    } else if (createdDate is DateTime) {
      propertyDate = createdDate;
    } else {
      print('  ❌ Invalid date format at root level');
      return false;
    }

    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    final isNew = propertyDate.isAfter(oneMonthAgo);
    
    print('  📅 Property date: $propertyDate, One month ago: $oneMonthAgo, Is new: $isNew');
    return isNew;
  } catch (e) {
    print('  ❌ Error parsing date for property: $e');
    return false;
  }
}

// Also add this debug method to your _loadProperties
Future<void> _loadProperties() async {
  print('🔄 Loading properties...');
  setState(() => _isLoading = true);
  
  try {
    final properties = await _propertyService.fetchProperties();
    print('📦 Total properties fetched: ${properties.length}');
    
    // Debug: Print raw data structure
    for (int i = 0; i < properties.length; i++) {
      final property = properties[i];
      print('\n📋 Raw Property ${i + 1}:');
      print('  🆔 ID: ${property['id']}');
      print('  📅 created_at: ${property['created_at']}');
      print('  🔍 Keys: ${property.keys.toList()}');
      
      if (property.containsKey('property_data')) {
        print('  📦 property_data keys: ${(property['property_data'] as Map).keys.toList()}');
      }
    }

    // Extract unique cities and locations
    final uniqueCities = <String>{};
    final uniqueLocations = <String>{};
    
    for (var property in properties) {
      Map<String, dynamic> propertyData = property;
      if (property.containsKey('property_data') && property['property_data'] is Map) {
        propertyData = property['property_data'] as Map<String, dynamic>;
      }
      
      final city = propertyData['city']?.toString().trim() ?? '';
      if (city.isNotEmpty && city != 'N/A') {
        uniqueCities.add(city);
      }
      
      final location = propertyData['location']?.toString().trim() ?? '';
      if (location.isNotEmpty && location != 'N/A' && location != 'No location') {
        uniqueLocations.add(location);
      }
    }

    setState(() {
      _properties.clear();
      _properties.addAll(properties);
      _cities = uniqueCities.toList()..sort();
      final allLocations = <String>{'All Locations'};
      allLocations.addAll(uniqueLocations);
      _locations = allLocations.toList()..sort();
    });
    

    
  } catch (e) {
    print('❌ Error loading properties: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading properties: $e')),
      );
    }
  } finally {
    setState(() => _isLoading = false);
  }
}
////.....................................
  // Update your filteredProperties getter in HomePage to handle nested data structure


// Update your _getAreaSuggestions method to handle nested structure
List<String> _getAreaSuggestions(String query) {
  if (query.isEmpty) return [];

  // Get all unique locations and landmarks from API data
  Set<String> allSearchableItems = {};

  for (var property in _properties) {
    // Handle both flat and nested structure
    Map<String, dynamic> propertyData = property;
    if (property.containsKey('property_data') && property['property_data'] is Map) {
      propertyData = property['property_data'] as Map<String, dynamic>;
    }
    
    // Add city
    final city = propertyData['city']?.toString().trim() ?? '';
    if (city.isNotEmpty && city != 'N/A') {
      allSearchableItems.add(city);
    }

    // Add location/area
    final location = propertyData['location']?.toString().trim() ?? '';
    if (location.isNotEmpty &&
        location != 'N/A' &&
        location != 'No location') {
      allSearchableItems.add(location);
      // Only add formatted version if city is different from location
      if (city.isNotEmpty && city != 'N/A' && city != location) {
        allSearchableItems.add('$location, $city');
      }
    }

    // Add landmarks
    final landmarks = propertyData['landmarks'] as List<dynamic>? ?? [];
    for (var landmark in landmarks) {
      final landmarkStr = landmark.toString().trim();
      if (landmarkStr.isNotEmpty && landmarkStr != 'N/A') {
        allSearchableItems.add(landmarkStr);
        // Only add formatted version if city is different from landmark
        if (city.isNotEmpty && city != 'N/A' && city != landmarkStr) {
          allSearchableItems.add('$landmarkStr, $city');
        }
      }
    }

    // Add title keywords (property names)
    final title = propertyData['title']?.toString().trim() ?? '';
    if (title.isNotEmpty && title != 'No title') {
      allSearchableItems.add(title);
    }
  }

  // Filter based on query and remove duplicates
  return allSearchableItems
      .where((item) => item.toLowerCase().contains(query.toLowerCase()))
      .toSet() // Remove duplicates
      .toList()
    ..sort();
}

  // Initialize with default value

  Future<void> _addProperty(Map<String, dynamic> propertyData) async {
    setState(() => _isLoading = true);
    try {
      final success = await _propertyService.addProperty(propertyData);
      if (success) {
        await _loadProperties(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to add property');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding property: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }



  // Helper method to show snackbars
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Updated phone handling methods
  void _handlePhoneButton(Map<String, dynamic>? contact) {
    print('DEBUG: _handlePhoneButton called with contact: $contact');

    if (contact == null) {
      _showSnackBar('No contact information available');
      return;
    }

    // Get all available phone numbers
    final Set<String> numbers = {};

    // Add direct phone if available
    final directPhone = contact['phone']?.toString().trim() ?? '';
    if (directPhone.isNotEmpty) {
      final formatted = _formatPhoneNumber(directPhone);
      if (formatted.isNotEmpty) {
        numbers.add(formatted);
        print('DEBUG: Added direct phone: $formatted');
      }
    }

    // Add phone numbers from array if available
    final phoneNumbers = contact['phoneNumbers'] as List<dynamic>? ?? [];
    for (var number in phoneNumbers) {
      final formatted = _formatPhoneNumber(number.toString().trim());
      if (formatted.isNotEmpty) {
        numbers.add(formatted);
        print('DEBUG: Added phone from array: $formatted');
      }
    }

    print('DEBUG: Total phone numbers found: ${numbers.length}');

    if (numbers.isEmpty) {
      _showSnackBar('No phone number available');
      return;
    }

    if (numbers.length == 1) {
      print('DEBUG: Single phone number - calling directly: ${numbers.first}');
      _callPhone(numbers.first);
    } else {
      print('DEBUG: Multiple phone numbers - showing dialog');
      // Show dialog to select from multiple numbers
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Select a number to call',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: numbers
                .map((number) => ListTile(
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: Text(
                        number,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        print('DEBUG: User selected number: $number');
                        _callPhone(number);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    try {
      // Ensure the phone number is properly formatted
      final formattedNumber = _formatPhoneNumber(phoneNumber);
      if (formattedNumber.isEmpty) {
        _showSnackBar('Invalid phone number');
        return;
      }

      final uri = Uri(scheme: 'tel', path: formattedNumber);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      _showSnackBar('Error making phone call: $e');
    }
  }

  String _formatPhoneNumber(String rawNumber) {
    // Remove all non-digit characters
    final digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle Indian numbers (add +91 if missing)
    if (digitsOnly.length == 10) {
      return '+91$digitsOnly'; // Indian number with country code
    }
    // Handle numbers with country code
    else if (digitsOnly.length > 10) {
      return '+${digitsOnly.replaceAll(RegExp(r'^0+'), '')}';
    }

    return ''; // Invalid number
  }

  // Also update the _openWhatsApp method to use the same logic for consistency
  void _openWhatsApp(Map<String, dynamic>? contact) {
    print('DEBUG: _openWhatsApp called with contact: $contact');
    if (contact == null) {
      _showSnackBar('No contact information available');
      return;
    }

    String phoneNumber = '';

    // First try to get from whatsapp field
    final whatsappNumber = contact['whatsapp']?.toString().trim() ?? '';

    if (whatsappNumber.isNotEmpty) {
      phoneNumber = whatsappNumber;
    } else {
      // Try the direct phone field
      final directPhone = contact['phone']?.toString().trim() ?? '';
      if (directPhone.isNotEmpty) {
        phoneNumber = directPhone;
      } else {
        // Fallback to phoneNumbers array
        final phoneNumbers = contact['phoneNumbers'] as List<dynamic>?;
        if (phoneNumbers != null && phoneNumbers.isNotEmpty) {
          phoneNumber = phoneNumbers.first.toString().trim();
        }
      }
    }

    if (phoneNumber.isEmpty) {
      _showSnackBar('No WhatsApp number available');
      return;
    }

    // Clean up phone number and ensure it has country code
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    // If number doesn't start with '+', assume it's an Indian number (+91)
    if (!cleaned.startsWith('+')) {
      // Remove any leading zeros
      cleaned = cleaned.replaceAll(RegExp(r'^0+'), '');
      // Add Indian country code if not present
      if (!cleaned.startsWith('91') && cleaned.length == 10) {
        cleaned = '91$cleaned';
      }
      cleaned = '+$cleaned';
    }

    print(
        'DEBUG: Launching https://wa.me/${cleaned.substring(1)}'); // Remove + for WhatsApp URL
    _launchURL('https://wa.me/${cleaned.substring(1)}');
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    print("Launching: $uri");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('❌ Could not launch $uri');
      _showSnackBar('Could not launch $url');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildPriceTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchSection1(),
          _buildFeaturedProperties(),
          const SizedBox(
            height: 20,
          ),
          const ContactUsPage()
        ],
      ),
    );
  }

  String _formatPrice(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else {
      return '₹${(value / 100000).toStringAsFixed(1)} L';
    }
  }

  void _showAddPropertyDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPropertyDialog(
        onPropertyAdded: _addProperty,
        properties: _properties,
      ),
    );
  }

  Widget _buildSearchSection1() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Hero Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Text(
                  'Find a home you\'ll',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'love',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover properties that match your lifestyle',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // In _buildSearchSection1 method, replace the tabs section with:
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPropertyTypeTab(
                      'Buy', _selectedPropertyType == 'All Properties'),
                  _buildPropertyTypeTab(
                      'Rent', _selectedPropertyType == 'Rent'),
                  _buildPropertyTypeTab(
                      'New Project', _selectedPropertyType == 'New Project'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Search Card - Mobile Responsive
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mobile-first responsive search layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Mobile layout (single column)
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          // Location Search
                          _buildMobileSearchField(),
                          const SizedBox(height: 12),

                          // Property Type dropdown
                          _buildMobileDropdown(
                            value: _selectedPropertyType == 'Rent'
                                ? 'Flat'
                                : _selectedPropertyType,
                            items: _selectedPropertyType == 'Rent'
                                ? [
                                    'Flat',
                                    'House',
                                    'Villa',
                                    'PG',
                                    'Office Space'
                                  ]
                                : [
                                    'All Properties',
                                    'Apartment',
                                    'Villa',
                                    'Plot',
                                    'Commercial'
                                  ],
                            icon: Icons.home,
                            hint: 'Property Type',
                            onChanged: (value) =>
                                setState(() => _selectedPropertyType = value!),
                          ),
                          const SizedBox(height: 12),

                          // Multi-select Location Button and Chips
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMultiSelectButton(
                                label: 'Locations',
                                selectedItems: _selectedLocations,
                                icon: Icons.location_on,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select Locations',
                                  items: _locations,
                                  selectedItems: _selectedLocations,
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      _selectedLocations = selected;
                                    });
                                  },
                                ),
                              ),
                              _buildLocationChips(),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Multi-select City Button and Chips
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMultiSelectButton(
                                label: 'Cities',
                                selectedItems: _selectedCities,
                                icon: Icons.location_city,
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select Cities',
                                  items: _cities,
                                  selectedItems: _selectedCities,
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      _selectedCities = selected;
                                    });
                                  },
                                ),
                              ),
                              _buildCityChips(),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Search Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final count = filteredProperties.length;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Found $count properties'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Search Properties',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    // Desktop layout (row)
                    else {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Location Search
                            Expanded(
                              flex: 3,
                              child: _buildCompactSearchField(),
                            ),
                            // Property Type Dropdown
                            Expanded(
                              flex: 2,
                              child: _buildCompactDropdown(
                                value: _selectedPropertyType == 'Rent'
                                    ? 'Flat'
                                    : _selectedPropertyType,
                                items: _selectedPropertyType == 'Rent'
                                    ? [
                                        'Flat',
                                        'House',
                                        'Villa',
                                        'PG',
                                        'Office Space'
                                      ]
                                    : [
                                        'All Properties',
                                        'Apartment',
                                        'Villa',
                                        'Plot',
                                        'Commercial'
                                      ],
                                icon: Icons.home,
                                onChanged: (value) => setState(
                                    () => _selectedPropertyType = value!),
                              ),
                            ),
                            // Multi-select Location Button (Desktop)
                            Expanded(
                              flex: 2,
                              child: _buildCompactMultiSelectButton(
                                selectedItems: _selectedLocations,
                                icon: Icons.location_on,
                                hint: 'Locations',
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select Locations',
                                  items: _locations,
                                  selectedItems: _selectedLocations,
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      _selectedLocations = selected;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Multi-select City Button (Desktop)
                            Expanded(
                              flex: 2,
                              child: _buildCompactMultiSelectButton(
                                selectedItems: _selectedCities,
                                icon: Icons.location_city,
                                hint: 'Cities',
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select Cities',
                                  items: _cities,
                                  selectedItems: _selectedCities,
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      _selectedCities = selected;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Search Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final count = filteredProperties.length;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Found $count properties'),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: const Icon(Icons.search, size: 20),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Advanced Filters (Collapsible)
                ExpansionTile(
                  title: Text(
                    'More Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 16),

                    // Price Range Slider
                    _buildPriceRangeSlider(),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedPropertyType = 'All Properties';
                                _selectedLocations = ['All Locations'];
                                _selectedCities = [];
                                _priceRange =
                                    const RangeValues(100000, 10000000);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final count = filteredProperties.length;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Applied filters • $count properties found'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

// Add these new mobile-specific helper methods:

// Multi-select Button for Mobile
  Widget _buildMultiSelectButton({
    required String label,
    required List<String> selectedItems,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    String displayText;
    if (selectedItems.isEmpty) {
      displayText = 'Select $label';
    } else if (selectedItems.contains('All Locations') ||
        selectedItems.contains('All Areas')) {
      displayText = 'All $label';
    } else if (selectedItems.length == 1) {
      displayText = selectedItems.first;
    } else {
      displayText = '${selectedItems.length} $label selected';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

// Compact Multi-select Button for Desktop
  Widget _buildCompactMultiSelectButton({
    required List<String> selectedItems,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
  }) {
    String displayText;
    if (selectedItems.isEmpty) {
      displayText = hint;
    } else if (selectedItems.contains('All Locations') ||
        selectedItems.contains('All Areas')) {
      displayText = 'All $hint';
    } else if (selectedItems.length == 1) {
      displayText = selectedItems.first;
    } else {
      displayText = '${selectedItems.length} selected';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

// Multi-select Dialog
  void _showMultiSelectDialog({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedItems);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Select All / Clear All buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              if (title.contains('Location')) {
                                tempSelected = ['All Locations'];
                              } else {
                                tempSelected = [];
                              }
                            });
                          },
                          child: Text(
                            title.contains('Location')
                                ? 'All Locations'
                                : 'Clear All',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected = List.from(items);
                            });
                          },
                          child: Text(
                            'Select All',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // List of items
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = tempSelected.contains(item);

                          return CheckboxListTile(
                            title: Text(
                              item,
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  // If selecting "All Locations", clear other selections
                                  if (item == 'All Locations') {
                                    tempSelected = ['All Locations'];
                                  } else {
                                    // Remove "All Locations" if selecting specific items
                                    tempSelected.remove('All Locations');
                                    tempSelected.add(item);
                                  }
                                } else {
                                  tempSelected.remove(item);
                                  // If no locations selected, default to "All Locations"
                                  if (tempSelected.isEmpty &&
                                      title.contains('Location')) {
                                    tempSelected.add('All Locations');
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                    // Selected count
                    if (tempSelected.isNotEmpty &&
                        !tempSelected.contains('All Locations'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${tempSelected.length} items selected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelectionChanged(tempSelected);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Mobile Search Field
  Widget _buildMobileSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TypeAheadField<String>(
        controller: _searchController,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by location, area, or landmark',
              hintStyle: const TextStyle(color: Colors.black, fontSize: 14),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          );
        },
        suggestionsCallback: (pattern) =>
            pattern.isEmpty ? [] : _getAreaSuggestions(pattern),
        itemBuilder: (context, suggestion) => ListTile(
          leading: Icon(Icons.location_on,
              color: Theme.of(context).colorScheme.primary, size: 16),
          title: Text(suggestion, style: GoogleFonts.poppins(fontSize: 14)),
          dense: true,
        ),
        onSelected: (suggestion) => _searchController.text = suggestion,
      ),
    );
  }

// Mobile Dropdown
  Widget _buildMobileDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.grey[600]),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

// Property Type Tab Builder
  Widget _buildPropertyTypeTab(String title, bool isSelected) {
    // Only show these three tabs
    final allowedTabs = ['Buy', 'Rent', 'New Project'];
    if (!allowedTabs.contains(title)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (title == 'Rent') {
                _selectedPropertyType = 'Rent';
              } else if (title == 'Buy') {
                _selectedPropertyType = 'All Properties';
              } else if (title == 'New Project') {
                // For New Project, we'll filter in the filteredProperties getter
                _selectedPropertyType = 'New Project';
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Compact Search Field
  Widget _buildCompactSearchField() {
    return SizedBox(
      height: 48,
      child: TypeAheadField<String>(
        controller: _searchController,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by location, area, or landmark',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          );
        },
        suggestionsCallback: (pattern) =>
            pattern.isEmpty ? [] : _getAreaSuggestions(pattern),
        itemBuilder: (context, suggestion) => ListTile(
          leading: Icon(Icons.location_on,
              color: Theme.of(context).colorScheme.primary, size: 16),
          title: Text(suggestion, style: GoogleFonts.poppins(fontSize: 14)),
          dense: true,
        ),
        onSelected: (suggestion) => _searchController.text = suggestion,
      ),
    );
  }

// Compact Dropdown
  Widget _buildCompactDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.grey[600]),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

// Price Range Slider
  Widget _buildPriceRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPriceTag(context, _formatPrice(_priceRange.start)),
            _buildPriceTag(context, _formatPrice(_priceRange.end)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 3,
          ),
          child: RangeSlider(
            values: _priceRange,
            min: 100000,
            max: 200000000,
            divisions: 100,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
        ),
      ],
    );
  }

  // Future<void> _loadProperties() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final properties = await _propertyService.fetchProperties();
  //     print('Total properties fetched: ${properties.length}');

  //     // Extract unique cities from properties
  //     final uniqueCities = properties
  //         .map((p) => p['city']?.toString().trim() ?? '')
  //         .where((city) => city.isNotEmpty && city != 'N/A')
  //         .toSet()
  //         .toList()
  //       ..sort();

  //     // Extract unique locations/areas from properties (remove duplicates)
  //     final uniqueLocations = properties
  //         .map((p) => p['location']?.toString().trim() ?? '')
  //         .where((location) =>
  //             location.isNotEmpty &&
  //             location != 'N/A' &&
  //             location != 'No location')
  //         .toSet()
  //         .toList()
  //       ..sort();

  //     setState(() {
  //       _properties.clear();
  //       _properties.addAll(properties);

  //       // Set cities list
  //       _cities = uniqueCities;

  //       // Set locations list (remove duplicates)
  //       final allLocations = <String>{'All Locations'};
  //       allLocations.addAll(uniqueLocations);
  //       _locations = allLocations.toList()..sort();
  //     });
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error loading properties: $e')),
  //       );
  //     }
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Widget _buildFeaturedProperties() {
    if (_isLoading && _properties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredProperties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _properties.isEmpty
                    ? 'No properties available'
                    : 'No properties found matching your criteria',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (_properties.isEmpty)
                TextButton(
                  onPressed: _loadProperties,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FadeInLeft(
                  child: Text(
                    'Featured Properties',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_isLoading && _properties.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final isMobile = constraints.maxWidth > 600;
              int crossAxisCount = 1;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }
              if (constraints.maxWidth > 900) {
                crossAxisCount = 3;
              }

              return MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = filteredProperties[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: PropertyCard(
                      isMobile: isMobile,
                      property: property,
                      onPhonePressed: () =>
                          _handlePhoneButton(property['contact']),
                      onWhatsAppPressed: () =>
                          _openWhatsApp(property['contact']),
                      onMapPressed: () => _launchURL(property['mapLink']),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Add this new method to build city chips:
  Widget _buildCityChips() {
    if (_selectedCities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _selectedCities.map((city) {
          return Chip(
            label: Text(
              city,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _selectedCities.remove(city);
              });
            },
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            deleteIconColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          );
        }).toList(),
      ),
    );
  }

  // Add this new method to build location chips:
  Widget _buildLocationChips() {
    if (_selectedLocations.isEmpty ||
        _selectedLocations.contains('All Locations')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _selectedLocations
            .where((loc) => loc != 'All Locations')
            .map((location) {
          return Chip(
            label: Text(
              location,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _selectedLocations.remove(location);
                if (_selectedLocations.isEmpty) {
                  _selectedLocations.add('All Locations');
                }
              });
            },
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            deleteIconColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildResponsiveAppBar(context, _selectedIndex, (index) {
        setState(() {
          _selectedIndex = index;
        });
      }),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadProperties,
              child: _buildBody(),
            ),
      floatingActionButton: !kIsWeb
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: _showAddPropertyDialog,
              tooltip: 'Add Property',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
