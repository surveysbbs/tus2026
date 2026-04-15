import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'services/supabase_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

import 'config/supabase_config.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);

      final box = await Hive.openBox('surveyBox');

      final supabaseService = SupabaseService(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      final List<Map<String, dynamic>> unsyncedData = [];

      for (final item in box.values) {
        if (item is Map) {
          final data = Map<String, dynamic>.from(item);
          final bool fromServer = data['fromServer'] == true;
          final int status = data['data_status'] ?? 0;

          if (!fromServer && status != 0) {
            unsyncedData.add(data);
          }
        }
      }

      if (unsyncedData.isNotEmpty) {
        await supabaseService.bulkUpsert(unsyncedData);

        for (int i = 0; i < box.length; i++) {
          final rawItem = box.getAt(i);

          if (rawItem is Map) {
            final item = Map<String, dynamic>.from(rawItem);

            final bool fromServer = item['fromServer'] == true;
            final int status = item['data_status'] ?? 0;

            if (!fromServer && status != 0) {
              item['fromServer'] = true;
              await box.putAt(i, item);
            }
          }
        }
      }

      await box.close();
      return true;
    } catch (e) {
      debugPrint("Background Sync Error: $e");
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Hive init
    await Hive.initFlutter();
    await Hive.openBox('surveyBox');
    await Hive.openBox('metaBox');

    // Supabase init
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    ).timeout(const Duration(seconds: 10));

    // Workmanager init
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // test করার সময় true
    );

    // আগে পুরনো task clear করা safer
    await Workmanager().cancelByUniqueName("unique_sync_task_id");

    await Workmanager().registerPeriodicTask(
      "unique_sync_task_id",
      "autoSyncTask",
      frequency: const Duration(minutes: 15), //30 korte hobe
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final metaBox = Hive.box('metaBox');
    final bool isLoggedIn = metaBox.get('is_logged_in', defaultValue: false);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, fontFamily: 'Nikosh'),
      home: isLoggedIn ? const DashboardPage() : const LoginPage(),
    );
  }
}
