import 'package:dio/dio.dart';
import 'package:tilahan_saathi/core/config/env.dart';
import 'package:tilahan_saathi/core/storage/token_storage.dart';

/// Shared Dio instance for talking to the Tilahan Saathi backend.
///
/// Automatically attaches the stored access token as a Bearer header, since
/// most endpoints (see the `HTTPBearer` security scheme) require it.
final dio = Dio(
  BaseOptions(
    baseUrl: Env.apiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ),
)..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
    ),
  );
