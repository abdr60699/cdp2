import '../entities/property.dart';
import '../repositories/property_repository.dart';
import '../../core/utils/result.dart';

class UpdateProperty {
  final PropertyRepository repository;

  UpdateProperty(this.repository);

  Future<Result<bool>> call(String id, Property property) async {
    return await repository.updateProperty(id, property);
  }
}