import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Map<String, dynamic>>> fetchProperties() async {
    try {
      final response = await _firestore
          .collection('properties')
          .orderBy('created_at', descending: true)
          .get();

      print('Raw response: ${response.docs.length} documents');

      return response.docs.map<Map<String, dynamic>>((doc) {
        final propertyData = Map<String, dynamic>.from(doc.data());

        propertyData['main_id'] = doc.id;
        if (propertyData['created_at'] is Timestamp) {
          propertyData['created_at'] = (propertyData['created_at'] as Timestamp).toDate().toIso8601String();
        }

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

        if (propertyData['landmark'] != null && propertyData['landmarks'] == null) {
          propertyData['landmarks'] = [propertyData['landmark']];
        } else if (propertyData['landmarks'] == null) {
          propertyData['landmarks'] = [];
        }

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
        print('Property data: $propertyData');
        return propertyData;
      }).toList();
    } catch (e) {
      print('Error fetching properties: $e');
      return [];
    }
  }

  Future<bool> addProperty(Map<String, dynamic> propertyData) async {
    try {
      propertyData['created_at'] = FieldValue.serverTimestamp();

      final result = await _firestore
          .collection('properties')
          .add(propertyData);

      print('Insert result: ${result.id}');
      return true;
    } catch (e) {
      print('Error adding property: $e');
      return false;
    }
  }

  Future<bool> updateProperty(String id, Map<String, dynamic> propertyData) async {
    try {
      await _firestore
          .collection('properties')
          .doc(id)
          .update(propertyData);
      return true;
    } catch (e) {
      print('Error updating property: $e');
      return false;
    }
  }

  Future<bool> deleteProperty(String id) async {
    try {
      await _firestore
          .collection('properties')
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting property: $e');
      return false;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      final filePath = 'property_images/$fileName';

      await _storage.ref(filePath).delete();

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}