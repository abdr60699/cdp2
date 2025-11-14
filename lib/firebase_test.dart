import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseTest {
  static Future<bool> testConnection() async {
    try {
      print('🔵 Testing Firebase connection...');

      // Initialize Firebase if not already done
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;

      // Try to add a test document
      print('🔵 Adding test document...');
      final testDoc = await firestore.collection('test').add({
        'message': 'Hello Firebase!',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Test document added with ID: ${testDoc.id}');

      // Try to read the document back
      print('🔵 Reading test document...');
      final docSnapshot = await testDoc.get();
      if (docSnapshot.exists) {
        print('✅ Test document read successfully: ${docSnapshot.data()}');
      }

      // Clean up - delete the test document
      print('🔵 Cleaning up test document...');
      await testDoc.delete();
      print('✅ Test document deleted');

      print('✅ Firebase connection test passed!');
      return true;
    } catch (e) {
      print('❌ Firebase connection test failed: $e');
      return false;
    }
  }

  static Future<bool> testPropertiesCollection() async {
    try {
      print('🔵 Testing properties collection...');

      final firestore = FirebaseFirestore.instance;

      // Try to read from properties collection
      print('🔵 Querying properties collection...');
      final querySnapshot = await firestore
          .collection('properties')
          .limit(5)
          .get();

      print('✅ Properties collection accessible. Found ${querySnapshot.docs.length} documents');

      for (var doc in querySnapshot.docs) {
        print('  - Document ID: ${doc.id}');
        final data = doc.data();
        print('  - Title: ${data['title'] ?? 'No title'}');
      }

      return true;
    } catch (e) {
      print('❌ Properties collection test failed: $e');
      return false;
    }
  }
}