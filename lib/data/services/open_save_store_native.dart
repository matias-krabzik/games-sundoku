import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sqlite_save_store.dart';

Future<SqliteSaveStore> openSaveStore() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final factory = Platform.isAndroid || Platform.isIOS || Platform.isMacOS
      ? mobile.databaseFactory
      : databaseFactoryFfi;
  return SqliteSaveStore.open(factory, path.join(directory.path, 'sundoku.db'));
}
