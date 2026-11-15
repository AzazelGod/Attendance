import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/utils/navigator_app.dart';
import 'package:attendance_check/utils/validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:attendance_check/services/firebase_service.dart';
import 'package:go_router/go_router.dart';

class AddInfoInAccountModel extends ChangeNotifier {
  final UserApp _userApp;
  final FirebaseService _firebaseService;
  bool _isSaving = false;

  AddInfoInAccountModel(this._userApp, this._firebaseService) {
    loadUserData();
  }

  String get email => _userApp.email;
  bool get isSaving => _isSaving;

  void setName(String value) {
    _userApp.setName(value.trim());
  }

  void setSurname(String value) {
    _userApp.setSurname(value.trim());
  }

  void setPatronymic(String value) {
    _userApp.setPatronymic(value.trim());
  }

  void setPhoneNumber(String value) {
    _userApp.setPhoneNumber(value);
  }

  void loadUserData() {
    User? user = _firebaseService.getCurrentUser();
    if (user != null) {
      _userApp.setEmail(user.email!);
      notifyListeners();
    }
  }

  void _goBack(BuildContext context){
    context.go(NavigatorRouse.avtoriz);
  }

  // Роль и группу выдаёт администратор, при регистрации они пустые
  Future<void> validateAndSave(BuildContext context) async {
    final error = Validator.validateRussianName(_userApp.surname, 'Фамилия') ??
        Validator.validateRussianName(_userApp.name, 'Имя') ??
        Validator.validateRussianName(_userApp.patronymic, 'Отчество', required: false) ??
        Validator.validatePhone(_userApp.phoneNumber);
    if (error != null) {
      Validator.showError(context, error);
      return;
    }

    _isSaving = true;
    notifyListeners();
    try {
      _userApp.setRule('');
      _userApp.setGroup('');
      await _firebaseService.saveUserData(_userApp);
      if (context.mounted) _goBack(context);
    } catch (e) {
      if (context.mounted) Validator.showError(context, 'Не удалось сохранить данные: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
