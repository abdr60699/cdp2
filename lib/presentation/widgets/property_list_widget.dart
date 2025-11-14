import 'package:flutter/material.dart';
import '../../domain/entities/property.dart';
import 'property_card_widget.dart';

class PropertyListWidget extends StatelessWidget {
  final List<Property> properties;

  const PropertyListWidget({
    super.key,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const Center(
        child: Text(
          'No properties found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PropertyCardWidget(property: properties[index]),
        );
      },
    );
  }
}