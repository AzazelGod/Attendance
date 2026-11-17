import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:flutter/material.dart';

class TagUserModel extends ChangeNotifier {
  // Возможные отметки: был / не был / уважительная причина. '' — не отмечен
  static const List<String> statuses = ['+', 'Н', 'У'];

  final SubjectSchedule subject;
  List<UserApp> _users = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _canEdit = false;
  FirebaseService firebaseService = FirebaseService();
  Map<String, String> userStatus = {};
  // Кого староста изменил вручную (сохраняем только их, чтобы не затереть свежие QR-отметки)
  final Set<String> _changed = {};

  TagUserModel(this.subject) {
    getUsers();
  }

  List<UserApp> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  // Отмечать может только староста, студенты только смотрят
  bool get canEdit => _canEdit;
  bool get hasChanges => _changed.isNotEmpty;

  int countOf(String status) => _users.where((u) => (userStatus[u.email] ?? '') == status).length;

  // Дата пары в формате ключа журнала
  String get _date => subject.classTime.toString().split(' ')[0].replaceAll('-', ' ');

  Future<void> getUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final me = UserApp.fromMap(await firebaseService.getUserData() ?? {});
      _canEdit = me.rule == UserApp.ruleHeadman;

      final data = await firebaseService.getAllUsers(subject.group);
      if (data != null) {
        _users = data.map((doc) => UserApp.fromMap(doc)).where((u) => u.needsGroup).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        await _loadStatuses();
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке пользователей: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStatuses() async {
    final loaded = await firebaseService.loadUserStatusFromFirestore(
        subject.group, subject.titleSubject, subject.classTime, _users);
    // Несохранённые ручные изменения не теряем
    for (final email in _changed) {
      loaded[email] = userStatus[email] ?? '';
    }
    userStatus = loaded;
  }

  // Подтянуть свежие отметки (например, кто только что отсканировал QR)
  Future<void> refresh() async {
    try {
      await _loadStatuses();
    } catch (e) {
      debugPrint('Ошибка при обновлении отметок: $e');
    }
    notifyListeners();
  }

  // Повторное нажатие на ту же отметку снимает её
  void updateUserStatus(String userId, String status) {
    if (!_canEdit) return;
    userStatus[userId] = userStatus[userId] == status ? '' : status;
    _changed.add(userId);
    notifyListeners();
  }

  Future<void> saveUserStatus(BuildContext context) async {
    if (!_canEdit || _changed.isEmpty) return;
    _isSaving = true;
    notifyListeners();
    try {
      final changedUsers = _users.where((u) => _changed.contains(u.email)).toList();
      await firebaseService.saveUserStatusToFirestore(
          subject.group, subject.titleSubject, _date, subject.classTime, changedUsers, userStatus);
      _changed.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно сохранены')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении данных: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении данных')),
        );
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
