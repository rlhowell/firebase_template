import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_functions_service.dart';

/// Provides the CloudFunctionsService configured for the default region.
/// Override the region by creating a separate provider:
///
///   final euFunctionsProvider = Provider<CloudFunctionsService>(
///     (ref) => CloudFunctionsService(region: 'europe-west1'),
///   );
final cloudFunctionsProvider = Provider<CloudFunctionsService>(
  (ref) => CloudFunctionsService(),
);
