import '../repositories/property_repository.dart';
import '../../core/utils/result.dart';

class DeleteProperty {
  final PropertyRepository repository;

  DeleteProperty(this.repository);

  Future<Result<bool>> call(String id) async {
    return await repository.deleteProperty(id);
  }
}