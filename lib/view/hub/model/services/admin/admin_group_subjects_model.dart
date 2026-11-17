import 'package:attendance_check/models/discipline.dart';
import 'package:attendance_check/models/group_subject.dart';
import 'package:attendance_check/models/subject.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';

// Какие предметы у группы, кто их ведёт, часы и аттестация
class AdminGroupSubjectsModel extends ChangeNotifier {
  final String group;
  final FirebaseService firebaseService = FirebaseService();
  List<GroupSubject> _groupSubjects = [];
  List<Subject> _subjects = [];
  List<UserApp> _teachers = [];
  bool _isLoading = true;

  AdminGroupSubjectsModel(this.group) {
    load();
  }

  List<GroupSubject> get groupSubjects => _groupSubjects;
  List<Subject> get subjects => _subjects;
  List<UserApp> get teachers => _teachers;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _groupSubjects = await firebaseService.getGroupSubjects(group);
      _groupSubjects.sort((a, b) => a.subjectTitle.compareTo(b.subjectTitle));
      _subjects = await firebaseService.getSubjects();
      _teachers = (await firebaseService.getAllUsersWithIds()).where((u) => u.isTeacher).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
    } catch (e) {
      debugPrint('Ошибка при загрузке предметов группы: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> add({
    required Subject? subject,
    required UserApp? teacher,
    required String hoursText,
    required AssessmentType assessmentType,
  }) async {
    if (subject == null) return 'Выберите предмет';
    if (teacher == null) return 'Выберите преподавателя';
    final hours = int.tryParse(hoursText.trim());
    if (hours == null || hours <= 0) return 'Укажите количество часов';
    if (_groupSubjects.any((gs) => gs.subjectId == subject.id)) {
      return 'Этот предмет уже есть у группы';
    }
    try {
      await firebaseService.addGroupSubject(GroupSubject(
        group: group,
        subjectId: subject.id,
        subjectTitle: subject.title,
        teacherUid: teacher.uid,
        teacherName: teacher.shortName,
        hours: hours,
        assessmentType: assessmentType,
      ));
      await load();
      return null;
    } catch (e) {
      return 'Не удалось сохранить: $e';
    }
  }

  Future<void> delete(GroupSubject groupSubject) async {
    await firebaseService.deleteGroupSubject(groupSubject.id);
    await load();
  }
}
