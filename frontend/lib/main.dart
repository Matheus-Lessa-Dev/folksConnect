import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

export 'app.dart' show FolksConnectApp;

void main() {
  usePathUrlStrategy();
  runApp(const FolksConnectApp());
}
