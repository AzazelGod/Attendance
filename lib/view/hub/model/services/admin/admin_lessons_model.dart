import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// Сгенерированные занятия группы по дням: можно убрать пару в конкретный день
class AdminLessonsModel extends ChangeNotifier {
  final String group;
  final FirebaseService firebaseService = FirebaseService();
  List<SubjectSchedule> _lessons = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  AdminLessonsModel(this.group) {
    load();
  }

  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lessons = await firebaseService.getLessonsForGroup(group);
    } catch (e) {
      debugPrint('Ошибка при загрузке занятий: $e');
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

  List<SubjectSchedule> lessonsForSelectedDay() {
    return _lessons.where((l) => isSameDay(l.classTime, _selectedDay)).toList()
      ..sort((a, b) => a.classTime.compareTo(b.classTime));
  }

  Future<void> deleteLesson(SubjectSchedule lesson) async {
    await firebaseService.deleteLesson(lesson.id);
    _lessons.remove(lesson);
    notifyListeners();
  }
}
