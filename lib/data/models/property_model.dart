import '../../domain/entities/property.dart';

class PropertyModel extends Property {
  const PropertyModel({
    super.mainId,
    required super.title,
    required super.location,
    required super.city,
    required super.type,
    required super.price,
    required super.rentAmount,
    required super.images,
    required super.forRent,
    required super.grounds,
    required super.mapLink,
    required super.ageYears,
    required super.bedrooms,
    required super.bathrooms,
    required super.waterTax,
    required super.squareFeet,
    required super.builtupArea,
    required super.propertyTax,
    required super.purpose,
    required super.propertyStatus,
    required super.negotiablePrice,
    required super.maintenanceCharges,
    required super.depositAmount,
    required super.floorNumber,
    required super.totalFloors,
    required super.parkingAvailable,
    required super.parkingCount,
    required super.balconyAvailable,
    required super.balconyCount,
    required super.furnishingStatus,
    required super.ownerType,
    required super.contactPerson,
    required super.description,
    required super.urgentSale,
    required super.landmarks,
    required super.contact,
    super.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      mainId: json['main_id'],
      title: json['title'] ?? 'No title',
      location: json['location'] ?? 'No location',
      city: json['city'] ?? 'N/A',
      type: json['type'] ?? 'N/A',
      price: (json['price'] ?? 0).toDouble(),
      rentAmount: (json['rentAmount'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      forRent: json['forRent'] ?? false,
      grounds: (json['grounds'] ?? 0).toDouble(),
      mapLink: json['mapLink'] ?? '',
      ageYears: json['ageYears'] ?? 0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      waterTax: (json['waterTax'] ?? 0).toDouble(),
      squareFeet: (json['squareFeet'] ?? 0).toDouble(),
      builtupArea: (json['builtupArea'] ?? 0).toDouble(),
      propertyTax: (json['propertyTax'] ?? 0).toDouble(),
      purpose: json['purpose'] ?? 'For Sale',
      propertyStatus: json['propertyStatus'] ?? 'New',
      negotiablePrice: json['negotiablePrice'] ?? false,
      maintenanceCharges: (json['maintenanceCharges'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      floorNumber: json['floorNumber'] ?? 0,
      totalFloors: json['totalFloors'] ?? 0,
      parkingAvailable: json['parkingAvailable'] ?? false,
      parkingCount: json['parkingCount'] ?? 0,
      balconyAvailable: json['balconyAvailable'] ?? false,
      balconyCount: json['balconyCount'] ?? 0,
      furnishingStatus: json['furnishingStatus'] ?? 'Unfurnished',
      ownerType: json['ownerType'] ?? 'Owner',
      contactPerson: json['contactPerson'] ?? '',
      description: json['description'] ?? '',
      urgentSale: json['urgentSale'] ?? false,
      landmarks: List<String>.from(json['landmarks'] ?? []),
      contact: PropertyContactModel.fromJson(json['contact'] ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'city': city,
      'type': type,
      'price': price,
      'rentAmount': rentAmount,
      'images': images,
      'forRent': forRent,
      'grounds': grounds,
      'mapLink': mapLink,
      'ageYears': ageYears,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'waterTax': waterTax,
      'squareFeet': squareFeet,
      'builtupArea': builtupArea,
      'propertyTax': propertyTax,
      'purpose': purpose,
      'propertyStatus': propertyStatus,
      'negotiablePrice': negotiablePrice,
      'maintenanceCharges': maintenanceCharges,
      'depositAmount': depositAmount,
      'floorNumber': floorNumber,
      'totalFloors': totalFloors,
      'parkingAvailable': parkingAvailable,
      'parkingCount': parkingCount,
      'balconyAvailable': balconyAvailable,
      'balconyCount': balconyCount,
      'furnishingStatus': furnishingStatus,
      'ownerType': ownerType,
      'contactPerson': contactPerson,
      'description': description,
      'urgentSale': urgentSale,
      'landmarks': landmarks,
      'contact': (contact as PropertyContactModel).toJson(),
    };
  }
}

class PropertyContactModel extends PropertyContact {
  const PropertyContactModel({
    required super.phone,
    required super.whatsapp,
    required super.phoneNumbers,
  });

  factory PropertyContactModel.fromJson(Map<String, dynamic> json) {
    return PropertyContactModel(
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      phoneNumbers: List<String>.from(json['phoneNumbers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'whatsapp': whatsapp,
      'phoneNumbers': phoneNumbers,
    };
  }
}