import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'sqlite_save_store.dart';

Future<SqliteSaveStore> openSaveStore() =>
    SqliteSaveStore.open(databaseFactoryFfiWeb, 'sundoku.db');
