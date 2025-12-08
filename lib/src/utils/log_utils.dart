import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

class LogUtils {
  static void log(dynamic message, {String tag = 'ad_log'}) {
    if (kDebugMode) {
      dev.log('$message', name: tag);
    }
  }
}
