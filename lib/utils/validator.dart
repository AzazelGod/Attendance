import 'package:flutter/material.dart';

class Validator {

  static void showError(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email не может быть пустым";
    }

    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(email)) {
      return "Некорректный формат email";
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Пароль не может быть пустым";
    }
    if (password.length < 8) {
      return "Пароль должен содержать не менее 8 символов";
    }
    // Password regex pattern: at least one digit, one letter, and one special character
    final passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]+$');
    if (!passwordRegExp.hasMatch(password)) {
      return "Пароль должен содержать буквы, цифры и специальные символы";
    }
    return null;
  }

  // Фамилия / имя / отчество: только русские буквы, допускается дефис (Петров-Водкин)
  static String? validateRussianName(String value, String field, {bool required = true}) {
    final v = value.trim();
    if (v.isEmpty) {
      return required ? '$field не может быть пустым' : null;
    }
    if (!RegExp(r'^[А-Яа-яЁё]+(-[А-Яа-яЁё]+)?$').hasMatch(v)) {
      return '$field: используйте только русские буквы';
    }
    return null;
  }

  // Телефон в формате +7 952 956 17 97
  static String? validatePhone(String phone) {
    if (phone.isEmpty) {
      return 'Номер телефона не может быть пустым';
    }
    if (!RegExp(r'^\+7 \d{3} \d{3} \d{2} \d{2}$').hasMatch(phone)) {
      return 'Введите номер в формате +7 XXX XXX XX XX';
    }
    return null;
  }

  // Группа вида БИСО-01-23
  static String? validateGroup(String group) {
    if (!RegExp(r'^[А-ЯЁ]{2,6}-\d{2}-\d{2}$').hasMatch(group)) {
      return 'Формат группы: БИСО-01-23';
    }
    return null;
  }
}
