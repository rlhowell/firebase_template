import 'package:app_links/app_links.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../config/app_config.dart';
import 'deep_link_service.dart';

class FirebaseDeepLinkService implements DeepLinkService {
  final AppLinks _appLinks;
  final FirebaseFunctions _functions;

  FirebaseDeepLinkService({
    AppLinks? appLinks,
    FirebaseFunctions? functions,
  })  : _appLinks = appLinks ?? AppLinks(),
        _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: AppConfig.instance.functionsRegion,
            );

  @override
  Stream<DeepLinkData> get incomingLinks =>
      _appLinks.uriLinkStream.asyncMap(_resolve).where((d) => d != null).cast();

  @override
  Future<DeepLinkData?> getInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri == null) return null;
    return _resolve(uri);
  }

  @override
  Future<DeepLinkData?> claimDeferredLink() async {
    final result =
        await _functions.httpsCallable('getLink').call({'isFirstOpen': true});
    return _fromMap(result.data as Map?);
  }

  @override
  Future<String> createShortLink({
    required String path,
    Map<String, String>? params,
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final result = await _functions.httpsCallable('createShortLink').call({
      'path': path,
      if (params != null) 'params': params,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return (result.data as Map)['shortUrl'] as String;
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  Future<DeepLinkData?> _resolve(Uri uri) async {
    final code = _extractCode(uri);
    if (code == null) return null;
    final result =
        await _functions.httpsCallable('getLink').call({'code': code});
    return _fromMap(result.data as Map?);
  }

  String? _extractCode(Uri uri) {
    final host = AppConfig.instance.deepLinkHost;
    final scheme = AppConfig.instance.customScheme;

    // Universal Link / App Link: https://<host>/l/<code>
    if (uri.scheme == 'https' &&
        uri.host == host &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'l') {
      return uri.pathSegments[1];
    }

    // Custom scheme: <scheme>://l/<code>
    if (uri.scheme == scheme &&
        uri.host == 'l' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments[0];
    }

    return null;
  }

  DeepLinkData? _fromMap(Map? data) {
    if (data == null) return null;
    return DeepLinkData(
      path: data['path'] as String,
      params: Map<String, String>.from((data['params'] as Map?) ?? {}),
    );
  }
}
