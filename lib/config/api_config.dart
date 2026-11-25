import 'package:flutter/foundation.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kDebugMode ? 'http://10.0.2.2:8080' : '',
);
