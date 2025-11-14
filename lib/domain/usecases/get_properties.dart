import '../entities/property.dart';
import '../repositories/property_repository.dart';
import '../../core/utils/result.dart';

class GetProperties {
  final PropertyRepository repository;

  GetProperties(this.repository);

  Future<Result<List<Property>>> call() async {
    return await repository.getProperties();
  }
}