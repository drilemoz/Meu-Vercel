import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models.dart';
import 'storage.dart';

abstract interface class DeployAlerts {
  Future<bool> requestPermission();
  Future<void> transitions(List<Deployment> previous, List<Deployment> current, Preferences prefs);
}
class LocalDeployAlerts implements DeployAlerts {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> initialize() async {
    if (_ready) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification')));
    _ready = true;
  }
  @override Future<bool> requestPermission() async {
    await initialize();
    return await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission() ?? false;
  }
  @override Future<void> transitions(List<Deployment> previous, List<Deployment> current, Preferences prefs) async {
    if ((!prefs.notifyFailure && !prefs.notifySuccess) || previous.isEmpty) return;
    await initialize();
    final before = {for (final d in previous) d.id: d.status};
    for (final d in current) {
      if (!before.containsKey(d.id) || before[d.id] == d.status) continue;
      final failed = d.status == 'ERROR' && prefs.notifyFailure;
      final ready = d.status == 'READY' && prefs.notifySuccess;
      if (!failed && !ready) continue;
      await _plugin.show(d.id.hashCode & 0x7fffffff,
        failed ? 'Deploy falhou' : 'Deploy concluído', '${d.name} · ${d.environmentLabel}',
        const NotificationDetails(android: AndroidNotificationDetails('deploys', 'Deploys',
          channelDescription: 'Mudanças detectadas durante a sincronização do aplicativo', importance: Importance.defaultImportance)));
    }
  }
}
