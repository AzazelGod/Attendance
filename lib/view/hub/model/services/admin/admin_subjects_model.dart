import 'package:attendance_check/models/subject.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';

class AdminSubjectsModel extends ChangeNotifier {
  final FirebaseService firebaseService = FirebaseService();
  List<Subject> _subjects = [];
  bool _isLoading = true;

  AdminSubjectsModel() {
    load();
  }

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _subjects = await firebaseService.getSubjects();
    } catch (e) {
      debugPrint('Ошибка при загрузке предметов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addSubject(String raw) async {
    final title = raw.trim();
    if (title.isEmpty) return 'Введите название';
    if (_subjects.any((s) => s.title.toLowerCase() == title.toLowerCase())) {
      return 'Такой предмет уже есть';
    }
    try {
      await firebaseService.addSubject(title);
      await load();
      return null;
    } catch (e) {
      return 'Не удалось добавить: $e';
    }
  }

  Future<void> deleteSubject(Subject subject) async {
    await firebaseService.deleteSubject(subject.id);
    await load();
  }
}
