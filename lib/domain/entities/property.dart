class Property {
  final String? mainId;
  final String title;
  final String location;
  final String city;
  final String type;
  final double price;
  final double rentAmount;
  final List<String> images;
  final bool forRent;
  final double grounds;
  final String mapLink;
  final int ageYears;
  final int bedrooms;
  final int bathrooms;
  final double waterTax;
  final double squareFeet;
  final double builtupArea;
  final double propertyTax;
  final String purpose;
  final String propertyStatus;
  final bool negotiablePrice;
  final double maintenanceCharges;
  final double depositAmount;
  final int floorNumber;
  final int totalFloors;
  final bool parkingAvailable;
  final int parkingCount;
  final bool balconyAvailable;
  final int balconyCount;
  final String furnishingStatus;
  final String ownerType;
  final String contactPerson;
  final String description;
  final bool urgentSale;
  final List<String> landmarks;
  final PropertyContact contact;
  final DateTime? createdAt;

  const Property({
    this.mainId,
    required this.title,
    required this.location,
    required this.city,
    required this.type,
    required this.price,
    required this.rentAmount,
    required this.images,
    required this.forRent,
    required this.grounds,
    required this.mapLink,
    required this.ageYears,
    required this.bedrooms,
    required this.bathrooms,
    required this.waterTax,
    required this.squareFeet,
    required this.builtupArea,
    required this.propertyTax,
    required this.purpose,
    required this.propertyStatus,
    required this.negotiablePrice,
    required this.maintenanceCharges,
    required this.depositAmount,
    required this.floorNumber,
    required this.totalFloors,
    required this.parkingAvailable,
    required this.parkingCount,
    required this.balconyAvailable,
    required this.balconyCount,
    required this.furnishingStatus,
    required this.ownerType,
    required this.contactPerson,
    required this.description,
    required this.urgentSale,
    required this.landmarks,
    required this.contact,
    this.createdAt,
  });

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      mainId: map['main_id']?.toString(),
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      type: map['type'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      rentAmount: (map['rentAmount'] ?? 0.0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      forRent: map['forRent'] ?? false,
      grounds: (map['grounds'] ?? 0.0).toDouble(),
      mapLink: map['mapLink'] ?? '',
      ageYears: map['ageYears'] ?? 0,
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      waterTax: (map['waterTax'] ?? 0.0).toDouble(),
      squareFeet: (map['squareFeet'] ?? 0.0).toDouble(),
      builtupArea: (map['builtupArea'] ?? 0.0).toDouble(),
      propertyTax: (map['propertyTax'] ?? 0.0).toDouble(),
      purpose: map['purpose'] ?? 'For Sale',
      propertyStatus: map['propertyStatus'] ?? 'New',
      negotiablePrice: map['negotiablePrice'] ?? false,
      maintenanceCharges: (map['maintenanceCharges'] ?? 0.0).toDouble(),
      depositAmount: (map['depositAmount'] ?? 0.0).toDouble(),
      floorNumber: map['floorNumber'] ?? 0,
      totalFloors: map['totalFloors'] ?? 0,
      parkingAvailable: map['parkingAvailable'] ?? false,
      parkingCount: map['parkingCount'] ?? 0,
      balconyAvailable: map['balconyAvailable'] ?? false,
      balconyCount: map['balconyCount'] ?? 0,
      furnishingStatus: map['furnishingStatus'] ?? 'Unfurnished',
      ownerType: map['ownerType'] ?? 'Owner',
      contactPerson: map['contactPerson'] ?? '',
      description: map['description'] ?? '',
      urgentSale: map['urgentSale'] ?? false,
      landmarks: List<String>.from(map['landmarks'] ?? []),
      contact: PropertyContact.fromMap(map['contact'] ?? {}),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}

class PropertyContact {
  final String phone;
  final String whatsapp;
  final List<String> phoneNumbers;

  const PropertyContact({
    required this.phone,
    required this.whatsapp,
    required this.phoneNumbers,
  });

  factory PropertyContact.fromMap(Map<String, dynamic> map) {
    return PropertyContact(
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
    );
  }
}