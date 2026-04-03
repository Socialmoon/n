import 'package:workmanager/workmanager.dart';

import 'background_alert_worker.dart';

Future<void> initializeBackgroundTasks() async {
  await Workmanager().initialize(
    backgroundAlertCallbackDispatcher,
    isInDebugMode: false,
  );
  await Workmanager().registerPeriodicTask(
    emergencyAlertBackgroundTask,
    emergencyAlertBackgroundTask,
    frequency: const Duration(minutes: 15),
  );
}