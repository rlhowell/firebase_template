import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class _CrashlyticsOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    try {
      FirebaseCrashlytics.instance.log(event.lines.join('\n'));
    } catch (_) {
      // Firebase not yet initialised — silently drop.
    }
  }
}

/// App-wide logger.
///
/// Debug builds  — all levels, pretty-printed to console.
/// Release builds — warning and above only, routed to Crashlytics as breadcrumbs.
///
/// Usage:
///   log.d('fetching user');
///   log.i('user signed in: ${user.uid}');
///   log.w('token refresh failed', error: e);
///   log.e('unhandled error', error: e, stackTrace: s);
final log = Logger(
  printer: kDebugMode
      ? PrettyPrinter(methodCount: 1, colors: false, printEmojis: true)
      : SimplePrinter(printTime: true, colors: false),
  output: kDebugMode ? ConsoleOutput() : _CrashlyticsOutput(),
  filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
);
