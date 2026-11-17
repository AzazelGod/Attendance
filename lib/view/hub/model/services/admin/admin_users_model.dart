import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';

class AdminUsersModel extends ChangeNotifier {
  final FirebaseService firebaseService = FirebaseService();
  List<UserApp> _users = [];
  List<String> _groups = [];
  bool _isLoading = true;
  bool _onlyIncomplete = false;
  String _search = '';

  AdminUsersModel() {
    load();
  }

  bool get isLoading => _isLoading;
  bool get onlyIncomplete => _onlyIncomplete;
  List<String> get groups => _groups;

  // Не заполнено: нет роли или нет группы у того, кому она нужна
  static bool isIncomplete(UserApp user) {
    return !user.hasRule || (user.needsGroup && user.group.isEmpty);
  }

  int get incompleteCount => _users.where(isIncomplete).length;

  List<UserApp> get users {
    final search = _search.toLowerCase();
    final list = _users.where((u) {
      if (_onlyIncomplete && !isIncomplete(u)) return false;
      if (search.isEmpty) return true;
      return u.fullName.toLowerCase().contains(search) ||
          u.email.toLowerCase().contains(search) ||
          u.group.toLowerCase().contains(search);
    }).toList();
    // Сначала незаполненные, потом по фамилии
    list.sort((a, b) {
      final ia = isIncomplete(a) ? 0 : 1;
      final ib = isIncomplete(b) ? 0 : 1;
      if (ia != ib) return ia - ib;
      return a.fullName.compareTo(b.fullName);
    });
    return list;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await firebaseService.getAllUsersWithIds();
      _groups = await firebaseService.getGroups();
    } catch (e) {
      debugPrint('Ошибка при загрузке пользователей: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOnlyIncomplete(bool value) {
    _onlyIncomplete = value;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value.trim();
    notifyListeners();
  }

  Future<void> saveUser(BuildContext context, UserApp user, String rule, String group) async {
    final updated = UserApp()..setRule(rule);
    // Преподавателю и администратору группа не нужна
    final newGroup = updated.needsGroup ? group : '';
    try {
      await firebaseService.updateUserRoleAndGroup(user.uid, rule, newGroup);
      user.setRule(rule);
      user.setGroup(newGroup);
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
