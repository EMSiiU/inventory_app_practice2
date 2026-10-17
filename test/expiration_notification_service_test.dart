import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_practice2/core/notifications/expiration_notification_service.dart';

void main() {
  group('expirationNotificationTime', () {
    test('schedules at 9 a.m. on the expiration date', () {
      final scheduled = expirationNotificationTime(
        DateTime(2030, 5, 6),
        now: DateTime(2030, 5, 5, 10),
      );

      expect(scheduled, DateTime(2030, 5, 6, 9));
    });

    test('does not schedule the day before expiration', () {
      final scheduled = expirationNotificationTime(
        DateTime(2030, 5, 6),
        now: DateTime(2030, 5, 5, 8),
      );

      expect(scheduled, DateTime(2030, 5, 6, 9));
      expect(scheduled!.day, 6);
    });

    test('does not schedule when 9 a.m. on the expiration day has passed', () {
      final scheduled = expirationNotificationTime(
        DateTime(2030, 5, 6),
        now: DateTime(2030, 5, 6, 9),
      );

      expect(scheduled, isNull);
    });

    test('does not schedule notifications for past expiration dates', () {
      final scheduled = expirationNotificationTime(
        DateTime(2030, 5, 5),
        now: DateTime(2030, 5, 6, 8),
      );

      expect(scheduled, isNull);
    });
  });
}
