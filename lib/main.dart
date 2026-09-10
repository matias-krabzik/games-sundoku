import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const BootstrapApp());
}
