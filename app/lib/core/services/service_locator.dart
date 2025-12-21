import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:terafy/package/http.dart';
import 'package:terafy/core/services/storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:terafy/core/data/repositories/therapist_repository_impl.dart';
import 'package:terafy/core/domain/repositories/therapist_repository.dart';

final sl = GetIt.instance;

const _defaultBaseUrl = 'http://localhost:8080';

Future<void> initilizeDependencies() async {
  AppLogger.func();
  // Register Plugins
  sl.registerLazySingleton<HttpClient>(() => DioHttpClient(baseUrl: _defaultBaseUrl, enableLogger: kDebugMode));
  sl.registerLazySingleton<StorageService>(() => StorageService());

  // Register Services
  sl.registerLazySingleton<TherapistRepository>(() => TherapistRepositoryImpl(httpClient: sl()));
}
