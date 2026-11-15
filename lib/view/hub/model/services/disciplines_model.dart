import 'package:attendance_check/models/discipline.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';

class DisciplinesModel extends ChangeNotifier {
  String  _userGroup = '';
  late List<Discipline> _disciplines;
  bool _isLoading = true;
  FirebaseService firebaseService = FirebaseService();

  DisciplinesModel() {
    _disciplines = [];
    getDisciplines();
  }

  Future<void> getDisciplines() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Предметы берутся из привязок group_subjects:
      // студенту — по его группе, преподавателю — те, что он ведёт
      final user = UserApp.fromMap(await firebaseService.getUserData() ?? {});
      _userGroup = user.group;
      final groupSubjects = user.isTeacher
          ? await firebaseService.getGroupSubjectsForTeacher(firebaseService.getCurrentUser()!.uid)
          : await firebaseService.getGroupSubjects(_userGroup);
      _disciplines = groupSubjects.map((gs) {
        return Discipline(
          title: user.isTeacher ? '${gs.subjectTitle} (${gs.group})' : gs.subjectTitle,
          hours: gs.hours,
          assessmentType: gs.assessmentType,
        );
      }).toList();
    } catch (e) {
      debugPrint('Ошибка при загрузке дисциплин: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  List<Discipline> get disciplines => _disciplines;
  bool get isLoading => _isLoading;
}
