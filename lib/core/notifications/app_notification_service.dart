import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initializing;

  static Future<void> initialize({void Function(String? payload)? onTap}) {
    return _initializing ??= _initialize(onTap);
  }

  static Future<void> _initialize(void Function(String? payload)? onTap) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      onTap?.call(launch?.notificationResponse?.payload);
    }
  }

  static Future<bool?> areNotificationsEnabled() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions()
          .then((permissions) => permissions?.isEnabled == true);
    }
    return null;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  static Future<void> openNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.openAppNotificationSettings();
  }

  static Future<void> showTestNotification() async {
    await initialize();
    if (await areNotificationsEnabled() != true) return;
    await _plugin.show(
      id: 7101,
      title: 'Christian Golfers notifications are on',
      body:
          'Round alerts will appear here and can be mirrored to your paired watch.',
      notificationDetails: _roundNotificationDetails,
      payload: 'notifications',
    );
  }

  static Future<void> showRoundStarted({
    required String roundId,
    required String courseName,
  }) async {
    await initialize();
    if (await areNotificationsEnabled() != true) return;
    await _plugin.show(
      id: roundId.hashCode,
      title: 'Your 4-ball has teed off',
      body: 'The round at $courseName has started. Tap to open the scorecard.',
      notificationDetails: _roundNotificationDetails,
      payload: 'round:$roundId',
    );
  }

  static const NotificationDetails _roundNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          'round_updates',
          'Round updates',
          channelDescription:
              'Updates when a round you joined starts on your device.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.social,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
