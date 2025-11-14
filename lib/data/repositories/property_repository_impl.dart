import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../core/utils/result.dart';
import '../../core/error/failures.dart';
import '../datasources/property_remote_data_source.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;

  PropertyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Property>>> getProperties() async {
    try {
      final properties = await remoteDataSource.getProperties();
      return Success(properties);
    } on ServerFailure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> addProperty(Property property) async {
    try {
      final propertyModel = _propertyToModel(property);
      final result = await remoteDataSource.addProperty(propertyModel);
      return Success(result);
    } on ServerFailure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> updateProperty(String id, Property property) async {
    try {
      final propertyModel = _propertyToModel(property);
      final result = await remoteDataSource.updateProperty(id, propertyModel);
      return Success(result);
    } on ServerFailure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> deleteProperty(String id) async {
    try {
      final result = await remoteDataSource.deleteProperty(id);
      return Success(result);
    } on ServerFailure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> deletePropertyImage(String imageUrl) async {
    try {
      final result = await remoteDataSource.deletePropertyImage(imageUrl);
      return Success(result);
    } on ServerFailure catch (failure) {
      return Error(failure);
    } catch (e) {
      return Error(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  PropertyModel _propertyToModel(Property property) {
    print('🔵 Converting Property to PropertyModel: ${property.title}');
    return PropertyModel(
      mainId: property.mainId,
      title: property.title,
      location: property.location,
      city: property.city,
      type: property.type,
      price: property.price,
      rentAmount: property.rentAmount,
      images: property.images,
      forRent: property.forRent,
      grounds: property.grounds,
      mapLink: property.mapLink,
      ageYears: property.ageYears,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      waterTax: property.waterTax,
      squareFeet: property.squareFeet,
      builtupArea: property.builtupArea,
      propertyTax: property.propertyTax,
      purpose: property.purpose,
      propertyStatus: property.propertyStatus,
      negotiablePrice: property.negotiablePrice,
      maintenanceCharges: property.maintenanceCharges,
      depositAmount: property.depositAmount,
      floorNumber: property.floorNumber,
      totalFloors: property.totalFloors,
      parkingAvailable: property.parkingAvailable,
      parkingCount: property.parkingCount,
      balconyAvailable: property.balconyAvailable,
      balconyCount: property.balconyCount,
      furnishingStatus: property.furnishingStatus,
      ownerType: property.ownerType,
      contactPerson: property.contactPerson,
      description: property.description,
      urgentSale: property.urgentSale,
      landmarks: property.landmarks,
      contact: PropertyContactModel(
        phone: property.contact.phone,
        whatsapp: property.contact.whatsapp,
        phoneNumbers: property.contact.phoneNumbers,
      ),
      createdAt: property.createdAt,
    );
  }
}