class DeepLinkData {
  final String path;
  final Map<String, String> params;

  const DeepLinkData({required this.path, this.params = const {}});

  @override
  String toString() => 'DeepLinkData(path: $path, params: $params)';
}

abstract class DeepLinkService {
  /// Fires whenever the app is foregrounded via a deep link while already running.
  Stream<DeepLinkData> get incomingLinks;

  /// Returns the link if the app was cold-started by tapping a deep link.
  Future<DeepLinkData?> getInitialLink();

  /// Checks for a deferred link — call once on first launch after install.
  /// Matches the click that was recorded when the user tapped the short link
  /// before the app was installed, using IP-based fingerprinting (10-minute window).
  Future<DeepLinkData?> claimDeferredLink();

  /// Creates a short link and returns its URL (e.g. https://myapp.web.app/l/abc123).
  /// Requires the user to be signed in.
  Future<String> createShortLink({
    required String path,
    Map<String, String>? params,
    String? title,
    String? description,
    String? imageUrl,
  });
}
