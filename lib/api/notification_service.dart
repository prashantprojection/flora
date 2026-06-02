import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: For iOS, we need to request permissions.
    // simpler setup for now, assuming Android mostly based on earlier file context
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    // Schedule a daily notification at 9:00 AM if it hasn't been scheduled yet.
    // In a real app, we would check if plants need water before *showing* it,
    // but for local notifications, we often schedule it and then cancel it if done,
    // or we schedule it to repeat daily and the user ignores it if they know.
    // Better logic: Schedule "Check your plants" daily at 9am.
    // The user requirement says: "Receive a push notification... so that I remember to water."
    // We will stick to a simple daily reminder for 9 AM.

    await _notificationsPlugin.zonedSchedule(
      id: 0, // ID
      title: 'Flora Reminder',
      body: 'Time to check on your plants! 🌱',
      scheduledDate: _nextInstanceOfNineAM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminds you to check your plants daily',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }

  Future<void> schedulePlantNotification(Plant plant) async {
    final int notificationId = plant.id.hashCode.abs();
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      plant.nextWatering.year,
      plant.nextWatering.month,
      plant.nextWatering.day,
      9, // 9 AM
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = now.add(const Duration(minutes: 1));
    }

    BigPictureStyleInformation? bigPictureStyleInformation;
    if (plant.imagePath != null && plant.imagePath!.isNotEmpty) {
      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(plant.imagePath!),
        hideExpandedLargeIcon: true,
        contentTitle: 'Time to water ${plant.name}!',
        summaryText: 'Your plant needs some attention 🌱',
      );
    }

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Time to water ${plant.name}!',
      body: 'Your plant needs some attention 🌱',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_care_channel',
          'Plant Care Reminders',
          channelDescription: 'Reminds you when specific plants need care',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        ),
        iOS: DarwinNotificationDetails(
          attachments: plant.imagePath != null && plant.imagePath!.isNotEmpty
              ? [DarwinNotificationAttachment(plant.imagePath!)]
              : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPlantNotification(String plantId) async {
    await _notificationsPlugin.cancel(id: plantId.hashCode.abs());
  }

  Future<void> rescheduleAllPlantNotifications(List<Plant> plants) async {
    await cancelAll();
    if (plants.isEmpty) {
      await scheduleDailyReminder();
      return;
    }
    
    for (final plant in plants) {
      if (plant.status == PlantStatus.active || plant.status == PlantStatus.quarantine || plant.status == null) {
        await schedulePlantNotification(plant);
      }
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
