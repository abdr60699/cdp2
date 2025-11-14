import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/get_properties.dart';
import '../../domain/usecases/add_property.dart';
import '../../domain/usecases/update_property.dart';
import '../../domain/usecases/delete_property.dart';
import '../../injection_container.dart' as di;
import '../../core/utils/result.dart';

final getPropertiesUseCaseProvider = Provider<GetProperties>((ref) {
  return di.sl<GetProperties>();
});

final addPropertyUseCaseProvider = Provider<AddProperty>((ref) {
  return di.sl<AddProperty>();
});

final updatePropertyUseCaseProvider = Provider<UpdateProperty>((ref) {
  return di.sl<UpdateProperty>();
});

final deletePropertyUseCaseProvider = Provider<DeleteProperty>((ref) {
  return di.sl<DeleteProperty>();
});

final propertyListProvider = StateNotifierProvider<PropertyNotifier, AsyncValue<List<Property>>>((ref) {
  return PropertyNotifier(
    getProperties: ref.watch(getPropertiesUseCaseProvider),
    addProperty: ref.watch(addPropertyUseCaseProvider),
    updateProperty: ref.watch(updatePropertyUseCaseProvider),
    deleteProperty: ref.watch(deletePropertyUseCaseProvider),
  );
});

class PropertyNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final GetProperties getProperties;
  final AddProperty addProperty;
  final UpdateProperty updateProperty;
  final DeleteProperty deleteProperty;

  PropertyNotifier({
    required this.getProperties,
    required this.addProperty,
    required this.updateProperty,
    required this.deleteProperty,
  }) : super(const AsyncValue.loading()) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    state = const AsyncValue.loading();

    final result = await getProperties();

    switch (result) {
      case Success<List<Property>>():
        state = AsyncValue.data(result.data);
      case Error<List<Property>>():
        state = AsyncValue.error(result.failure.message, StackTrace.current);
    }
  }

  Future<void> addPropertyItem(Property property) async {
    print('🔵 Starting to add property: ${property.title}');
    final result = await addProperty(property);

    switch (result) {
      case Success<bool>():
        print('✅ Property added successfully, reloading list...');
        await loadProperties();
        print('✅ Property list reloaded');
      case Error<bool>():
        print('❌ Error adding property: ${result.failure.message}');
        state = AsyncValue.error(result.failure.message, StackTrace.current);
    }
  }

  Future<void> updatePropertyItem(String id, Property property) async {
    final result = await updateProperty(id, property);

    switch (result) {
      case Success<bool>():
        await loadProperties();
      case Error<bool>():
        state = AsyncValue.error(result.failure.message, StackTrace.current);
    }
  }

  Future<void> deletePropertyItem(String id) async {
    final result = await deleteProperty(id);

    switch (result) {
      case Success<bool>():
        await loadProperties();
      case Error<bool>():
        state = AsyncValue.error(result.failure.message, StackTrace.current);
    }
  }
}