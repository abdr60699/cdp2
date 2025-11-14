import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_providers.dart';
import '../widgets/property_list_widget.dart';
import '../../add_property_dialog.dart';
import '../../domain/entities/property.dart';
import '../../firebase_test.dart';

class HomePageWrapper extends ConsumerWidget {
  const HomePageWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HomePage();
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsyncValue = ref.watch(propertyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Dream Property'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Testing Firebase connection...')),
              );

              final connectionTest = await FirebaseTest.testConnection();
              final propertiesTest = await FirebaseTest.testPropertiesCollection();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      connectionTest && propertiesTest
                        ? '✅ Firebase tests passed! Check console for details.'
                        : '❌ Firebase tests failed! Check console for errors.'
                    ),
                    backgroundColor: connectionTest && propertiesTest
                      ? Colors.green
                      : Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: propertiesAsyncValue.when(
        data: (properties) => PropertyListWidget(properties: properties),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(propertyListProvider.notifier).loadProperties();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final properties = propertiesAsyncValue.value ?? [];
              await showDialog(
                context: context,
                builder: (context) => AddPropertyDialog(
                  properties: properties.map((p) => {
                    'main_id': p.mainId,
                    'title': p.title,
                    'location': p.location,
                    'city': p.city,
                    'type': p.type,
                    'price': p.price,
                    'images': p.images,
                  }).toList(),
                  onPropertyAdded: (propertyData) async {
                    // Convert the property data to a Property entity and save it
                    final property = Property.fromMap(propertyData);
                    await ref.read(propertyListProvider.notifier).addPropertyItem(property);
                  },
                ),
              );
            },
            backgroundColor: const Color(0xFFFF6B00),
            heroTag: "add",
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              ref.read(propertyListProvider.notifier).loadProperties();
            },
            backgroundColor: const Color(0xFFFF6B00),
            heroTag: "refresh",
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}