import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';
import 'data/datasources/property_remote_data_source.dart';
import 'data/repositories/property_repository_impl.dart';
import 'domain/repositories/property_repository.dart';
import 'domain/usecases/get_properties.dart';
import 'domain/usecases/add_property.dart';
import 'domain/usecases/update_property.dart';
import 'domain/usecases/delete_property.dart';

final sl = GetIt.instance;

Future<void> init() async {
  print('🔵 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(
      firestore: sl(),
      storage: sl(),
    ),
  );

  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetProperties(sl()));
  sl.registerLazySingleton(() => AddProperty(sl()));
  sl.registerLazySingleton(() => UpdateProperty(sl()));
  sl.registerLazySingleton(() => DeleteProperty(sl()));

}