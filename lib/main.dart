import 'package:flutter/material.dart';
import 'package:kichub_loca/app/app.dart';
import 'package:kichub_loca/core/services/connectivity_service.dart';
import 'package:kichub_loca/core/services/notification_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (SupabaseService.isConfigured) {
      await SupabaseService.initialize();
    }
    await AppNotificationService.initialize();
    await ConnectivityService.initialize();
  } catch (error) {
    debugPrint('Initialization failed: $error');
  }

  runApp(const KichubApp());
}
