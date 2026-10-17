import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../data/models/product_batch_model.dart';
import '../../data/repositories/batch_repository.dart';

DateTime? expirationNotificationTime(DateTime expirationDate, {DateTime? now}) {
  final scheduledTime = DateTime(
    expirationDate.year,
    expirationDate.month,
    expirationDate.day,
    9,
  );
  if (!scheduledTime.isAfter(now ?? DateTime.now())) return null;
  return scheduledTime;
}

class ExpirationNotificationService {
  ExpirationNotificationService._();

  static final ExpirationNotificationService instance =
      ExpirationNotificationService._();
  static const _channelId = 'expiration_alerts';
  static const _payloadPrefix = 'expiration-batch:';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final BatchRepository _batchRepository = BatchRepository();

  Future<void>? _initializing;
  bool _initialized = false;

  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    final currentInitialization = _initializing;
    if (currentInitialization != null) {
      await currentInitialization;
      return;
    }

    final initialization = _initialize();
    _initializing = initialization;
    try {
      await initialization;
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!isSupported) return false;

    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<bool> scheduleBatchExpiration({
    required int batchId,
    required String productName,
    required DateTime expirationDate,
  }) async {
    await initialize();
    if (!isSupported) return false;

    final localSchedule = expirationNotificationTime(expirationDate);
    if (localSchedule == null) return false;
    final scheduledDate = timezone.TZDateTime.from(
      localSchedule,
      timezone.local,
    );

    await _notifications.zonedSchedule(
      id: batchId,
      title: 'Caducidad de producto',
      body: 'El lote de $productName vence hoy.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Caducidad de productos',
          channelDescription: 'Recordatorios de artículos que caducan hoy.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix$batchId',
    );
    return true;
  }

  Future<void> scheduleTestNotification() async {
    if (!kDebugMode) {
      throw StateError(
        'Las notificaciones de prueba solo están disponibles '
        'en modo depuración.',
      );
    }
    await initialize();
    if (!isSupported) {
      throw UnsupportedError(
        'Las notificaciones de prueba requieren Android o iOS.',
      );
    }

    await _notifications.zonedSchedule(
      id: 2147483647,
      title: 'Prueba de alarma',
      body: 'Las notificaciones locales están funcionando.',
      scheduledDate: timezone.TZDateTime.now(timezone.local)
          .add(const Duration(minutes: 1)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Caducidad de productos',
          channelDescription: 'Recordatorios de artículos que caducan hoy.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'expiration-test',
    );
  }

  Future<void> synchronizeActiveBatches() async {
    await initialize();
    if (!isSupported) return;

    final activeBatches = await _batchRepository.getActiveAlarmBatches();
    final batchesToSchedule = <ProductBatchModel>[];
    final desiredNotificationIds = <int>{};

    for (final batch in activeBatches) {
      final batchId = batch.id;
      final productName = batch.productName;
      if (batchId == null ||
          productName == null ||
          expirationNotificationTime(batch.expirationDate) == null) {
        continue;
      }
      desiredNotificationIds.add(batchId);
      batchesToSchedule.add(batch);
    }

    final pendingNotifications = await _notifications
        .pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      if (notification.payload?.startsWith(_payloadPrefix) == true &&
          !desiredNotificationIds.contains(notification.id)) {
        await _notifications.cancel(id: notification.id);
      }
    }

    for (final batch in batchesToSchedule) {
      await scheduleBatchExpiration(
        batchId: batch.id!,
        productName: batch.productName!,
        expirationDate: batch.expirationDate,
      );
    }
  }
}
