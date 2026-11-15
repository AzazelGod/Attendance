enum Rule {
  none, // роль ещё не назначена администратором
  student,
  teacher,
  headman,
  admin,
}

class UserApp {
  // Названия ролей, как они хранятся в Firestore
  static const String ruleStudent = 'Студент';
  static const String ruleHeadman = 'Староста';
  static const String ruleTeacher = 'Преподаватель';
  static const String ruleAdmin = 'Администратор';
  static const List<String> allRules = [ruleStudent, ruleHeadman, ruleTeacher, ruleAdmin];

  String _uid = '';
  String _name = '';
  String _surname = '';
  String _patronymic = '';
  String _email = '';
  String _phoneNumber = '';
  String _group = '';
  List<String> _subjects = [];
  Rule _rule = Rule.none;

  String get uid => _uid;
  String get name => _name;
  String get surname => _surname;
  String get patronymic => _patronymic;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  String get group => _group;
  List<String> get subjects => _subjects;

  // Пустая строка, если роль не назначена
  String get rule {
    switch (_rule) {
      case Rule.student:
        return ruleStudent;
      case Rule.headman:
        return ruleHeadman;
      case Rule.teacher:
        return ruleTeacher;
      case Rule.admin:
        return ruleAdmin;
      case Rule.none:
        return '';
    }
  }

  bool get hasRule => _rule != Rule.none;
  bool get isTeacher => _rule == Rule.teacher;
  bool get isAdmin => _rule == Rule.admin;

  // Группа нужна всем, кроме преподавателя и администратора
  bool get needsGroup => !isTeacher && !isAdmin;

  // «Иванов Иван Иванович»
  String get fullName => [_surname, _name, _patronymic].where((s) => s.isNotEmpty).join(' ');

  // «Иванов И.И.» — так преподаватель показывается в расписании
  String get shortName {
    final initials = [_name, _patronymic]
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0]}.')
        .join();
    return initials.isEmpty ? _surname : '$_surname $initials';
  }

  void setUid(String value) {
    _uid = value;
  }

  void setName(String value) {
    _name = value;
  }

  void setSurname(String value) {
    _surname = value;
  }

  void setPatronymic(String value) {
    _patronymic = value;
  }

  void setEmail(String value) {
    _email = value;
  }

  void setPhoneNumber(String value) {
    _phoneNumber = value;
  }

  void setGroup(String value) {
    _group = value;
  }

  void setSubjects(List<String> value) {
    _subjects = value;
  }

  void setRule(String value) {
    switch (value) {
      case ruleStudent:
        _rule = Rule.student;
        break;
      case ruleHeadman:
        _rule = Rule.headman;
        break;
      case ruleTeacher:
      case 'Преподователь': // старое написание в базе
        _rule = Rule.teacher;
        break;
      case ruleAdmin:
        _rule = Rule.admin;
        break;
      default:
        _rule = Rule.none;
    }
  }

  // Заполнение из документа users/{uid}
  static UserApp fromMap(Map<String, dynamic> doc, {String uid = ''}) {
    return UserApp()
      ..setUid(uid)
      ..setName(doc['name'] ?? '')
      ..setSurname(doc['surname'] ?? '')
      ..setPatronymic(doc['patronymic'] ?? '')
      ..setPhoneNumber(doc['phoneNumber'] ?? '')
      ..setEmail(doc['email'] ?? '')
      ..setGroup(doc['group'] ?? '')
      ..setRule(doc['rule'] ?? '');
  }
}
