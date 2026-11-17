import 'package:attendance_check/models/group_subject.dart';
import 'package:attendance_check/models/schedule_template.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:attendance_check/utils/navigator_app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScheduleModel extends ChangeNotifier {
  final FirebaseService firebaseService = FirebaseService();
  List<String> _groups = [];
  String? _group;
  ScheduleTemplate? _template;
  List<GroupSubject> _groupSubjects = [];
  List<UserApp> _teachers = [];
  int _week = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  AdminScheduleModel() {
    _loadGroups();
  }

  List<String> get groups => _groups;
  String? get group => _group;
  ScheduleTemplate? get template => _template;
  List<GroupSubject> get groupSubjects => _groupSubjects;
  List<UserApp> get teachers => _teachers;
  int get week => _week;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasChanges => _hasChanges;

  Future<void> _loadGroups() async {
    try {
      _groups = await firebaseService.getGroups();
      _teachers = (await firebaseService.getAllUsersWithIds()).where((u) => u.isTeacher).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
    } catch (e) {
      debugPrint('Ошибка при загрузке групп: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGroup(String group) async {
    _group = group;
    _isLoading = true;
    _hasChanges = false;
    notifyListeners();
    try {
      _template = await firebaseService.getScheduleTemplate(group);
      _groupSubjects = await firebaseService.getGroupSubjects(group);
      _groupSubjects.sort((a, b) => a.subjectTitle.compareTo(b.subjectTitle));
    } catch (e) {
      debugPrint('Ошибка при загрузке шаблона: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setWeek(int week) {
    _week = week;
    notifyListeners();
  }

  void setSemesterStart(DateTime date) {
    _template!.semesterStart = date;
    _changed();
  }

  void setSemesterEnd(DateTime date) {
    _template!.semesterEnd = date;
    _changed();
  }

  List<TemplateLesson> lessonsFor(int weekday) {
    return _template!.lessons.where((l) => l.week == _week && l.weekday == weekday).toList()
      ..sort((a, b) => a.pair.compareTo(b.pair));
  }

  // Номера пар, уже занятых в этот день (с учётом подгруппы)
  bool isPairBusy(int weekday, int pair, String subgroup) {
    return _template!.lessons.any((l) =>
        l.week == _week &&
        l.weekday == weekday &&
        l.pair == pair &&
        (l.subgroup == subgroup || l.subgroup == subgroups[0] || subgroup == subgroups[0]));
  }

  void addLesson(TemplateLesson lesson) {
    _template!.lessons.add(lesson);
    _changed();
  }

  void removeLesson(TemplateLesson lesson) {
    _template!.lessons.remove(lesson);
    _changed();
  }

  // Удобно, если недели почти одинаковые: скопировать текущую неделю в другую
  void copyWeekToOther() {
    final other = _week == 1 ? 2 : 1;
    _template!.lessons.removeWhere((l) => l.week == other);
    final copies = _template!.lessons
        .where((l) => l.week == _week)
        .map((l) => TemplateLesson.fromMap({...l.toMap(), 'week': other}))
        .toList();
    _template!.lessons.addAll(copies);
    _changed();
  }

  void _changed() {
    _hasChanges = true;
    notifyListeners();
  }

  Future<String> saveTemplate() async {
    _isSaving = true;
    notifyListeners();
    try {
      await firebaseService.saveScheduleTemplate(_template!);
      _hasChanges = false;
      return 'Шаблон сохранён';
    } catch (e) {
      return 'Не удалось сохранить шаблон: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Сохраняет шаблон и заполняет занятия с сегодняшнего дня до конца семестра
  Future<String> generate() async {
    final t = _template!;
    if (t.semesterStart == null || t.semesterEnd == null) {
      return 'Укажите даты начала и конца семестра';
    }
    if (t.semesterEnd!.isBefore(t.semesterStart!)) {
      return 'Конец семестра раньше начала';
    }
    if (t.lessons.isEmpty) return 'В шаблоне нет пар';
    _isSaving = true;
    notifyListeners();
    try {
      await firebaseService.saveScheduleTemplate(t);
      _hasChanges = false;
      final count = await firebaseService.generateSchedule(t, DateTime.now());
      return 'Создано занятий: $count';
    } catch (e) {
      return 'Ошибка при заполнении: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void goLessons(BuildContext context) {
    context.push(NavigatorRouse.adminLessons, extra: _group);
  }
}
