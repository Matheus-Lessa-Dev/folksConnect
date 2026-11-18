import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/authentication_service.dart';

export 'app.dart' show FolksConnectApp;

void main() {
  usePathUrlStrategy();
  final apiClient = ApiClient();
  final authService = HttpAuthenticationService(apiClient);
  runApp(FolksConnectApp(
    authentication: authService,
    apiClient: apiClient,
  ));
}
