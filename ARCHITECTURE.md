# Clean Architecture with Riverpod

This Flutter project follows Clean Architecture principles with Riverpod for state management.

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # App-wide constants
│   ├── error/
│   │   └── failures.dart               # Error handling abstractions
│   └── utils/
│       └── result.dart                 # Result wrapper for operations
├── domain/
│   ├── entities/
│   │   └── property.dart               # Core business entities
│   ├── repositories/
│   │   └── property_repository.dart    # Repository contracts
│   └── usecases/
│       ├── get_properties.dart         # Business logic use cases
│       ├── add_property.dart
│       ├── update_property.dart
│       └── delete_property.dart
├── data/
│   ├── models/
│   │   └── property_model.dart         # Data models with JSON serialization
│   ├── datasources/
│   │   └── property_remote_data_source.dart # External data access
│   └── repositories/
│       └── property_repository_impl.dart    # Repository implementations
├── presentation/
│   ├── providers/
│   │   └── property_providers.dart     # Riverpod providers
│   ├── pages/
│   │   └── home_page.dart              # UI pages
│   └── widgets/
│       ├── property_list_widget.dart   # Reusable UI components
│       └── property_card_widget.dart
├── injection_container.dart            # Dependency injection setup
└── main.dart                          # App entry point
```

## Architecture Layers

### 1. Domain Layer (Business Logic)
- **Entities**: Core business objects with no dependencies
- **Use Cases**: Business logic operations
- **Repository Interfaces**: Contracts for data access

### 2. Data Layer (External Concerns)
- **Models**: Data representations with JSON serialization
- **Data Sources**: External API/database access
- **Repository Implementations**: Concrete implementations

### 3. Presentation Layer (UI)
- **Providers**: Riverpod state management
- **Pages**: Screen widgets
- **Widgets**: Reusable UI components

### 4. Core Layer (Shared)
- **Constants**: App-wide configuration
- **Errors**: Error handling abstractions
- **Utils**: Shared utilities

## State Management with Riverpod

### Providers Used:
- `StateNotifierProvider<PropertyNotifier, AsyncValue<List<Property>>>` for property list state
- Individual `Provider<UseCase>` for each use case
- `AsyncValue` for handling loading, success, and error states

### Key Benefits:
- ✅ Compile-time safety
- ✅ Less boilerplate than BLoC
- ✅ Better performance with selective rebuilds
- ✅ Easy testing with provider overrides
- ✅ Automatic cleanup and disposal

## Dependency Injection

Uses GetIt for dependency injection with clean separation:
- Data sources registered as lazy singletons
- Repositories registered as lazy singletons
- Use cases registered as lazy singletons
- UI accesses dependencies through Riverpod providers

## Error Handling

- `Result<T>` wrapper for operations (Success/Error)
- `Failure` abstractions for different error types
- `AsyncValue` in Riverpod handles loading/error states elegantly

## Usage Examples

### Watching Property List:
```dart
final propertiesAsyncValue = ref.watch(propertyListProvider);

propertiesAsyncValue.when(
  data: (properties) => PropertyListWidget(properties: properties),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Triggering Actions:
```dart
// Refresh properties
ref.read(propertyListProvider.notifier).loadProperties();

// Add new property
ref.read(propertyListProvider.notifier).addPropertyItem(newProperty);
```

This architecture ensures:
- 🎯 **Separation of Concerns**
- 🔄 **Dependency Inversion**
- 🧪 **Easy Testing**
- 📈 **Scalability**
- 🛠️ **Maintainability**