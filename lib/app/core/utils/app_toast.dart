import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Thin wrapper over `toastification`. Works without a `BuildContext` because
/// `ToastificationWrapper` is mounted above `GetMaterialApp` in `main.dart`.
class AppToast {
  AppToast._();

  static const Duration _duration = Duration(seconds: 3);

  static void success(String message, {String? title}) => _show(
        type: ToastificationType.success,
        title: title ?? 'Berhasil',
        message: message,
      );

  static void error(String message, {String? title}) => _show(
        type: ToastificationType.error,
        title: title ?? 'Gagal',
        message: message,
      );

  static void warning(String message, {String? title}) => _show(
        type: ToastificationType.warning,
        title: title ?? 'Perhatian',
        message: message,
      );

  static void info(String message, {String? title}) => _show(
        type: ToastificationType.info,
        title: title ?? 'Info',
        message: message,
      );

  static void _show({
    required ToastificationType type,
    required String title,
    required String message,
  }) {
    toastification.show(
      type: type,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: _duration,
      title: Text(title),
      description: Text(message),
      showProgressBar: false,
      dragToClose: true,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
