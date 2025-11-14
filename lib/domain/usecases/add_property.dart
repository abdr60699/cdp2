import '../entities/property.dart';
import '../repositories/property_repository.dart';
import '../../core/utils/result.dart';

class AddProperty {
  final PropertyRepository repository;

  AddProperty(this.repository);

  Future<Result<bool>> call(Property property) async {
    return await repository.addProperty(property);
  }
}