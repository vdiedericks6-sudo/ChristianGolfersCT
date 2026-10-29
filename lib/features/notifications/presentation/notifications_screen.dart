import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/app_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loading = true;
  bool? _enabled;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await AppNotificationService.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _enable() async {
    setState(() => _working = true);
    try {
      final granted = await AppNotificationService.requestPermission();
      await _refresh();
      if (granted) await AppNotificationService.showTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notifications enabled. Check your phone and paired watch.'
                : 'Notification permission was not granted. You can enable it in Android settings.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not enable notifications: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() => _working = true);
    try {
      await AppNotificationService.showTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent to this device.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send a test notification: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _settings() async {
    await AppNotificationService.openNotificationSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.pageBg,
    appBar: AppBar(
      backgroundColor: AppTheme.darkNavy,
      leading: const AppBackButton(),
      title: const Text('Notifications'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ChristianGolfersCard(
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppTheme.primaryGreen,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round alerts',
                      style: AppTheme.body(15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loading
                          ? 'Checking device permission…'
                          : _enabled == true
                          ? 'Enabled on this device'
                          : _enabled == false
                          ? 'Disabled in device settings'
                          : 'Permission status is not available on this platform',
                      style: AppTheme.body(12, colour: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (_enabled == true)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'When a playing partner starts a round while you are in its lobby, the app posts a round alert. Android can mirror that phone notification to a paired Wear OS watch when notification sharing is enabled for both devices.',
          style: AppTheme.body(13, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _loading || _working || _enabled == true ? null : _enable,
          icon: _working
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_active_outlined),
          label: Text(
            _working ? 'Working…' : 'Enable notifications and send a test',
          ),
        ),
        if (_enabled == true) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _working ? null : _sendTest,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send test notification'),
          ),
        ],
        if (_enabled == false) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _working ? null : _settings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open notification settings'),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'For watch delivery, keep Christian Golfers notifications allowed in the phone’s notification settings and enable notification sharing for the app in your watch companion app. Push alerts while the app is closed require additional server push setup.',
          style: AppTheme.body(12, colour: AppTheme.textMuted),
        ),
      ],
    ),
  );
}
