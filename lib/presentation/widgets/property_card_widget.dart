import 'package:flutter/material.dart';
import '../../domain/entities/property.dart';
import '../../models/format_inr.dart';

class PropertyCardWidget extends StatelessWidget {
  final Property property;

  const PropertyCardWidget({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  property.images.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text(
              property.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${property.location}, ${property.city}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  property.forRent
                      ? 'Rent: ₹${Inr.formatIndianNumber(property.rentAmount.toInt().toString())}/month'
                      : 'Price: ₹${Inr.formatIndianNumber(property.price.toInt().toString())}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: property.forRent ? Colors.green : Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    property.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (property.bedrooms > 0) ...[
                  const Icon(Icons.bed, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${property.bedrooms} bed'),
                  const SizedBox(width: 16),
                ],
                if (property.bathrooms > 0) ...[
                  const Icon(Icons.bathtub, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${property.bathrooms} bath'),
                  const SizedBox(width: 16),
                ],
                if (property.squareFeet > 0) ...[
                  const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${property.squareFeet.toInt()} sqft'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}