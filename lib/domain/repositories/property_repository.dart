import '../entities/property.dart';
import '../../core/utils/result.dart';

abstract class PropertyRepository {
  Future<Result<List<Property>>> getProperties();
  Future<Result<bool>> addProperty(Property property);
  Future<Result<bool>> updateProperty(String id, Property property);
  Future<Result<bool>> deleteProperty(String id);
  Future<Result<bool>> deletePropertyImage(String imageUrl);
}