import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:attendance_check/utils/navigator_app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class MagazineModel extends ChangeNotifier {
  List<SubjectSchedule> _list = [];
  bool _isLoading = true;
  FirebaseService firebaseService = FirebaseService();
  String _userGroup = '';
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  MagazineModel() {
    getSchedule();
  }

  List<SubjectSchedule> get list => _list;
  bool get isLoading => _isLoading;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;

  Future<void> getSchedule() async {
    try {
      _isLoading = true;
      notifyListeners();
      _userGroup = await firebaseService.getUserField('group') ?? '';
      if (_userGroup.isNotEmpty) {
        _list = await firebaseService.getLessonsForGroup(_userGroup);
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке расписания: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Пары выбранного дня по времени
  List<SubjectSchedule> getSchedulesForDay(DateTime day) {
    return _list.where((schedule) => isSameDay(schedule.classTime, day)).toList()
      ..sort((a, b) => a.classTime.compareTo(b.classTime));
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  void goToday() {
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    notifyListeners();
  }

  void goTagUserView(BuildContext context, SubjectSchedule lesson) {
    context.push(NavigatorRouse.tagUser, extra: lesson);
  }
}
