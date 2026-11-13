import 'dart:async';
import 'dart:convert';
import 'package:attendance_check/models/subject_schedule.dart';
import 'package:flutter/material.dart';

class QrGeneretionModel extends ChangeNotifier {
  // Как часто меняется QR-код
  static const Duration refreshInterval = Duration(seconds: 15);

  final SubjectSchedule subject;
  late Timer _timer;
  late String _qrData;

  QrGeneretionModel(this.subject) {
    _qrData = _buildQrData();
    _startTimer();
  }

  String get qrData => _qrData;

  // В QR кладём данные занятия и время генерации,
  // по времени студент проверяет, что код свежий
  String _buildQrData() {
    return jsonEncode({
      'type': 'attendance',
      'group': subject.group,
      'subject': subject.titleSubject,
      'classTime': subject.classTime.toIso8601String(),
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(refreshInterval, (timer) {
      _qrData = _buildQrData();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
