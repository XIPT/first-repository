import 'dart:io';
import 'dart:html' as html; // 웹 알림을 위해 추가
import 'package:flutter/foundation.dart'; // kIsWeb 확인용
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (!kIsWeb) {
      // 모바일/데스크톱 알림 초기화
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
      final InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notificationsPlugin.initialize(settings);
    }
  }

  Future<void> showNotification(int id, String title, String body) async {
    if (kIsWeb) {
      // ✅ 웹에서는 JavaScript Notification API 직접 사용
      if (html.Notification.supported) {
        html.Notification.requestPermission().then((permission) {
          if (permission == 'granted') {
            html.Notification(title, body: body);
          }
        });
      }
    } else {
      // ✅ 모바일/데스크톱에서는 `flutter_local_notifications` 사용
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details =
      NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(id, title, body, details);
    }
  }
}
