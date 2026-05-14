import 'package:cloud_functions/cloud_functions.dart';

import '../utils/app_logger.dart';

/// Wrapper around Firebase Callable Functions.
///
/// The Firebase SDK automatically attaches:
///   - The signed-in user's ID token (JWT) on every call
///   - The App Check token (since App Check is activated in bootstrap)
///
/// There is no need to pass auth or App Check tokens manually — that was a
/// FlutterFlow limitation, not a Firebase one.
class CloudFunctionsService {
  final FirebaseFunctions _functions;

  /// [region] defaults to 'us-central1'. Pass your function's region if different,
  /// e.g. CloudFunctionsService(region: 'europe-west1').
  CloudFunctionsService({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(region: region);

  /// Calls a Firebase Callable Function and returns its result data.
  ///
  /// [name]    — the function name as deployed (e.g. 'createOrder')
  /// [data]    — optional request payload
  /// [timeout] — defaults to 30 s; increase for long-running operations
  ///
  /// Throws [FirebaseFunctionsException] on function errors. The exception's
  /// [code] field maps to standard gRPC status codes:
  ///   'unauthenticated'   — no signed-in user
  ///   'permission-denied' — user lacks permission
  ///   'not-found'         — function or resource not found
  ///   'invalid-argument'  — bad request data
  ///   'internal'          — unhandled exception inside the function
  Future<T> call<T>(
    String name, {
    Object? data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    log.d('Calling function: $name');
    try {
      final result = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: timeout),
          )
          .call<T>(data);
      log.d('Function $name succeeded');
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      log.e('Function $name failed [${e.code}]: ${e.message}', error: e);
      rethrow;
    }
  }

  /// Routes all function calls to the local Firebase emulator.
  /// Call this in main_dev.dart when running `firebase emulators:start --only functions`.
  ///
  /// Example:
  ///   CloudFunctionsService.useEmulator(); // localhost:5001
  static void useEmulator({String host = 'localhost', int port = 5001}) {
    FirebaseFunctions.instance.useFunctionsEmulator(host, port);
  }
}
