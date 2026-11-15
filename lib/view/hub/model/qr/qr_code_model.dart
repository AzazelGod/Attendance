import 'dart:convert';
import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/utils/navigator_app.dart';
import 'package:flutter/material.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';


class QrCodeModel extends ChangeNotifier {
  late UserApp _userApp;
  final FirebaseService firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _isTeacher = false;
  List<SubjectSchedule> _list = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  QrCodeModel() {
    _userApp = UserApp();
    getUserRoleAndSchedule();
  }

  bool get isLoading => _isLoading;
  bool get isTeacher => _isTeacher;
  List<SubjectSchedule> get list => _list;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;

  Future<void> getUserRoleAndSchedule() async {
    try {
      final role = await firebaseService.getUserField('rule');
      if (role != null) {
        _userApp.setRule(role);
        _isTeacher = _userApp.isTeacher;
        if (_isTeacher) {
          await getTeacherSchedule();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTeacherSchedule() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Только занятия, к которым администратор привязал этого преподавателя
      final uid = firebaseService.getCurrentUser()?.uid;
      if (uid != null) {
        _list = await firebaseService.getLessonsForTeacher(uid);
        _list.sort((a, b) => a.classTime.compareTo(b.classTime));
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке расписания: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void onFormatChanged(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  List<SubjectSchedule> getSchedulesForDay(DateTime day) {
    return _list.where((schedule) =>
    schedule.classTime.year == day.year &&
        schedule.classTime.month == day.month &&
        schedule.classTime.day == day.day
    ).toList();
  }

  void goQrGeneration(BuildContext context, SubjectSchedule schedule){
    context.push(NavigatorRouse.qrGeneration, extra: schedule);
  }

  // ---- Сканирование QR студентом ----

  // Сколько живёт QR-код: 15 с обновление + запас на расхождение часов
  static const Duration _qrMaxAge = Duration(seconds: 30);

  bool _isProcessing = false;
  String? _scanMessage;
  bool _scanSuccess = false;

  bool get isProcessing => _isProcessing;
  String? get scanMessage => _scanMessage;
  bool get scanSuccess => _scanSuccess;

  Future<void> onQrScanned(String? rawValue) async {
    if (_isProcessing || _scanMessage != null || rawValue == null) return;
    _isProcessing = true;
    notifyListeners();
    try {
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(rawValue) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Это не QR-код занятия');
      }
      if (data['type'] != 'attendance') {
        throw Exception('Это не QR-код занятия');
      }

      final createdAt = DateTime.fromMillisecondsSinceEpoch(data['ts'] as int);
      if (DateTime.now().difference(createdAt).abs() > _qrMaxAge) {
        throw Exception('QR-код устарел, отсканируйте текущий код');
      }

      final userData = await firebaseService.getUserData();
      final userGroup = userData?['group'] ?? '';
      final userEmail = userData?['email'] ?? '';
      if (userGroup != data['group']) {
        throw Exception('Это занятие другой группы');
      }

      final classTime = DateTime.parse(data['classTime'] as String);
      final date = classTime.toString().split(' ')[0].replaceAll('-', ' ');
      final user = UserApp()..setEmail(userEmail);
      await firebaseService.saveUserStatusToFirestore(
          userGroup, data['subject'], date, classTime, [user], {userEmail: '+'});

      _scanSuccess = true;
      _scanMessage = 'Вы отмечены на занятии «${data['subject']}»';
    } catch (e) {
      _scanSuccess = false;
      _scanMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void resetScan() {
    _scanMessage = null;
    _scanSuccess = false;
    notifyListeners();
  }
}
