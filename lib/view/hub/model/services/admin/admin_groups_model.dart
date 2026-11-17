import 'package:attendance_check/services/firebase_service.dart';
import 'package:attendance_check/utils/navigator_app.dart';
import 'package:attendance_check/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminGroupsModel extends ChangeNotifier {
  final FirebaseService firebaseService = FirebaseService();
  List<String> _groups = [];
  bool _isLoading = true;

  AdminGroupsModel() {
    load();
  }

  List<String> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _groups = await firebaseService.getGroups();
    } catch (e) {
      debugPrint('Ошибка при загрузке групп: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Возвращает текст ошибки или null, если группа добавлена
  Future<String?> addGroup(String raw) async {
    final name = raw.trim().toUpperCase();
    final error = Validator.validateGroup(name);
    if (error != null) return error;
    try {
      final added = await firebaseService.addGroup(name);
      if (!added) return 'Группа $name уже есть';
      await load();
      return null;
    } catch (e) {
      return 'Не удалось добавить группу: $e';
    }
  }

  Future<void> deleteGroup(String name) async {
    await firebaseService.deleteGroup(name);
    await load();
  }

  void goGroupSubjects(BuildContext context, String group) {
    context.push(NavigatorRouse.adminGroupSubjects, extra: group);
  }
}
