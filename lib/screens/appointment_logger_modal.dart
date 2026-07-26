import 'package:flutter/material.dart';
import '../services/gamification_service.dart';
import 'appointment_manager_modal.dart';

export 'appointment_manager_modal.dart';

/// Legacy helper redirecting to unified appointment manager.
Future<void> showAppointmentLogger({
  required BuildContext context,
  required String userId,
  required GamificationService gamificationService,
  required void Function(LogEventResult result) onLogged,
}) {
  return showAppointmentManager(
    context: context,
    userId: userId,
    gamificationService: gamificationService,
    onLogged: onLogged,
  );
}
