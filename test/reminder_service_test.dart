import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spineup/services/reminder_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reminder settings default to off at 6:00 PM', () async {
    final settings = await ReminderService.load(ownerUserId: 'owner-1');

    expect(settings.enabled, isFalse);
    expect(settings.hour, 18);
    expect(settings.minute, 0);
  });

  test('disabling a reminder persists the off state and chosen time', () async {
    await ReminderService.disable(ownerUserId: 'owner-1');
    final settings = await ReminderService.load(ownerUserId: 'owner-1');

    expect(settings.enabled, isFalse);
    expect(settings.hour, 18);
    expect(settings.minute, 0);
  });

  test('clear removes the saved reminder preference', () async {
    await ReminderService.disable(ownerUserId: 'owner-1');
    await ReminderService.clear(ownerUserId: 'owner-1');
    final settings = await ReminderService.load(ownerUserId: 'owner-1');

    expect(settings.enabled, isFalse);
    expect(settings.hour, 18);
    expect(settings.minute, 0);
  });
}
