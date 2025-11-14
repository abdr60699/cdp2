import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/property_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties();
  Future<bool> addProperty(PropertyModel property);
  Future<bool> updateProperty(String id, PropertyModel property);
  Future<bool> deleteProperty(String id);
  Future<bool> deletePropertyImage(String imageUrl);
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  PropertyRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<PropertyModel>> getProperties() async {
    try {
      print('🔵 Fetching properties from Firebase...');
      final querySnapshot = await firestore
          .collection(AppConstants.propertiesCollection)
          .orderBy('created_at', descending: true)
          .get();

      print('🔵 Found ${querySnapshot.docs.length} properties in Firebase');

      return querySnapshot.docs.map<PropertyModel>((doc) {
        final propertyData = Map<String, dynamic>.from(doc.data());

        propertyData['main_id'] = doc.id;
        if (propertyData['created_at'] is Timestamp) {
          propertyData['created_at'] = (propertyData['created_at'] as Timestamp).toDate().toIso8601String();
        }

        _setDefaultValues(propertyData);
        _handleLandmarks(propertyData);
        _handleContact(propertyData);

        print('🔵 Processing property: ${propertyData['title']} (ID: ${doc.id})');
        return PropertyModel.fromJson(propertyData);
      }).toList();
    } catch (e) {
      print('❌ Error fetching properties: $e');
      throw ServerFailure('Failed to fetch properties: ${e.toString()}');
    }
  }

  @override
  Future<bool> addProperty(PropertyModel property) async {
    try {
      print('🔵 Adding property to Firebase: ${property.title}');
      final propertyData = property.toJson();
      propertyData['created_at'] = FieldValue.serverTimestamp();

      print('🔵 Property data: $propertyData');
      print('🔵 Collection: ${AppConstants.propertiesCollection}');

      final docRef = await firestore
          .collection(AppConstants.propertiesCollection)
          .add(propertyData);

      print('✅ Property added to Firebase with ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('❌ Firebase error: $e');
      throw ServerFailure('Failed to add property: ${e.toString()}');
    }
  }

  @override
  Future<bool> updateProperty(String id, PropertyModel property) async {
    try {
      await firestore
          .collection(AppConstants.propertiesCollection)
          .doc(id)
          .update(property.toJson());
      return true;
    } catch (e) {
      throw ServerFailure('Failed to update property: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteProperty(String id) async {
    try {
      await firestore
          .collection(AppConstants.propertiesCollection)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      throw ServerFailure('Failed to delete property: ${e.toString()}');
    }
  }

  @override
  Future<bool> deletePropertyImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      final filePath = 'property_images/$fileName';

      await storage.ref(filePath).delete();

      return true;
    } catch (e) {
      throw ServerFailure('Failed to delete image: ${e.toString()}');
    }
  }

  void _setDefaultValues(Map<String, dynamic> propertyData) {
    propertyData['city'] = propertyData['city'] ?? 'N/A';
    propertyData['type'] = propertyData['type'] ?? 'N/A';
    propertyData['price'] = propertyData['price'] ?? 0;
    propertyData['title'] = propertyData['title'] ?? 'No title';
    propertyData['images'] = propertyData['images'] ?? [];
    propertyData['forRent'] = propertyData['forRent'] ?? false;
    propertyData['grounds'] = propertyData['grounds'] ?? 0;
    propertyData['mapLink'] = propertyData['mapLink'] ?? '';
    propertyData['ageYears'] = propertyData['ageYears'] ?? 0;
    propertyData['bedrooms'] = propertyData['bedrooms'] ?? 0;
    propertyData['location'] = propertyData['location'] ?? 'No location';
    propertyData['waterTax'] = propertyData['waterTax'] ?? 0;
    propertyData['bathrooms'] = propertyData['bathrooms'] ?? 0;
    propertyData['rentAmount'] = propertyData['rentAmount'] ?? 0;
    propertyData['squareFeet'] = propertyData['squareFeet'] ?? 0;
    propertyData['builtupArea'] = propertyData['builtupArea'] ?? 0;
    propertyData['propertyTax'] = propertyData['propertyTax'] ?? 0;
    propertyData['purpose'] = propertyData['purpose'] ?? 'For Sale';
    propertyData['propertyStatus'] = propertyData['propertyStatus'] ?? 'New';
    propertyData['negotiablePrice'] = propertyData['negotiablePrice'] ?? false;
    propertyData['maintenanceCharges'] = propertyData['maintenanceCharges'] ?? 0;
    propertyData['depositAmount'] = propertyData['depositAmount'] ?? 0;
    propertyData['floorNumber'] = propertyData['floorNumber'] ?? 0;
    propertyData['totalFloors'] = propertyData['totalFloors'] ?? 0;
    propertyData['parkingAvailable'] = propertyData['parkingAvailable'] ?? false;
    propertyData['parkingCount'] = propertyData['parkingCount'] ?? 0;
    propertyData['balconyAvailable'] = propertyData['balconyAvailable'] ?? false;
    propertyData['balconyCount'] = propertyData['balconyCount'] ?? 0;
    propertyData['furnishingStatus'] = propertyData['furnishingStatus'] ?? 'Unfurnished';
    propertyData['ownerType'] = propertyData['ownerType'] ?? 'Owner';
    propertyData['contactPerson'] = propertyData['contactPerson'] ?? '';
    propertyData['description'] = propertyData['description'] ?? '';
    propertyData['urgentSale'] = propertyData['urgentSale'] ?? false;
  }

  void _handleLandmarks(Map<String, dynamic> propertyData) {
    if (propertyData['landmark'] != null && propertyData['landmarks'] == null) {
      propertyData['landmarks'] = [propertyData['landmark']];
    } else if (propertyData['landmarks'] == null) {
      propertyData['landmarks'] = [];
    }
  }

  void _handleContact(Map<String, dynamic> propertyData) {
    if (propertyData['contact'] == null) {
      propertyData['contact'] = {
        'phone': '',
        'whatsapp': '',
        'phoneNumbers': []
      };
    } else {
      final contact = propertyData['contact'];
      if (contact['phone'] == null && contact['phoneNumbers'] != null && contact['phoneNumbers'].isNotEmpty) {
        contact['phone'] = contact['phoneNumbers'][0];
      }
      if (contact['whatsapp'] == null) {
        contact['whatsapp'] = contact['phone'] ?? '';
      }
    }
  }
}