import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flora/api/notification_service.dart';
import 'package:flora/services/update_service.dart';
import 'package:flora/models/diagnosis_record.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  Hive.registerAdapter(DiagnosisRecordAdapter());
  await Hive.openBox<DiagnosisRecord>('diagnosis_history');

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    UpdateService.checkAndForceUpdate(); // Check for Update when App Starts
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Flora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    );
  }
}
