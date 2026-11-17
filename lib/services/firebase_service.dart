import 'package:attendance_check/models/group_subject.dart';
import 'package:attendance_check/models/schedule_template.dart';
import 'package:attendance_check/models/subject.dart';
import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить текущего пользователя
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Регистрация пользователя
  Future<User?> register(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      throw Exception("Пользователь с таким email уже существует");
    } catch (e) {
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // await sendVerificationEmail();
        return result.user;
      } catch (e) {
        throw Exception("Ошибка при регистрации пользователя: ${e.toString()}");
      }
    }
  }

  // Вход в систему


  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // if (!result.user!.emailVerified) {
      //   throw Exception("Пожалуйста, подтвердите свой email");
      // }
      return result.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          throw Exception("Пользователя не существует");
        } else if (e.code == 'wrong-password') {
          throw Exception("Неверный пароль");
        }
      }
      throw Exception("Ошибка при входе пользователя: ${e.toString()}");
    }
  }

  // // Отправить письмо для подтверждения email
  // Future<void> sendVerificationEmail() async {
  //   User? user = _auth.currentUser;
  //   if (user != null && !user.emailVerified) {
  //     await user.sendEmailVerification();
  //   }
  // }
  //
  // // Проверка подтверждения email
  // Future<bool> isEmailVerified() async {
  //   User? user = _auth.currentUser;
  //   if (user != null) {
  //     await user.reload();
  //     return user.emailVerified;
  //   }
  //   return false;
  // }

  // Сохранить данные пользователя
  Future<void> saveUserData(UserApp userApp) async {
    User? user = getCurrentUser();
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': userApp.name,
        'surname': userApp.surname,
        'patronymic': userApp.patronymic,
        'email': userApp.email,
        'phoneNumber': userApp.phoneNumber,
        'group': userApp.group,
        'rule': userApp.rule,
      });
    }
  }

  // Загрузить данные пользователя
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = getCurrentUser();
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      throw Exception("Ошибка при загрузке данных пользователя: ${e.toString()}");
    }
    return null;
  }

  // Выход из аккаунта
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception("Ошибка при выходе из аккаунта: ${e.toString()}");
    }
  }

  // Получить данные пользователя (роль или группу)
  Future<String?> getUserField(String field) async {
    try {
      final data = await getUserData();
      return data?[field];
    } catch (e) {
      throw Exception('Ошибка при получении данных пользователя: $e');
    }
  }

  // Метод для получения всех дисциплин по группе
  Future<List<Map<String, dynamic>>?> getAllDisciplines(String speciality) async {
    try {
      String collectionName = speciality.split('-')[0];
      QuerySnapshot querySnapshot = await _firestore
          .collection('disciplines')
          .doc('discipline')
          .collection(collectionName)
          .get();

      List<Map<String, dynamic>> disciplines = querySnapshot.docs.map((doc) {
        debugPrint('Document data: ${doc.data()}');
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return disciplines;
    } catch (e) {
      throw Exception('Ошибка при получении дисциплин: $e');
    }
  }

  // Метод для получения всех пользователей по группе
  Future<List<Map<String, dynamic>>?> getAllUsers(String group) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('group', isEqualTo: group)
          .get();

      List<Map<String, dynamic>> users = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return users;
    } catch (e) {
      debugPrint('Ошибка при получении пользователей: $e');
      throw Exception('Ошибка при получении пользователей: $e');
    }
  }


  // Метод для получения расписания конкретной группы
  Future<List<Map<String, dynamic>>?> getScheduleForGroup(String group) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('group', isEqualTo: group)
          .get();

      List<Map<String, dynamic>> schedules = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return schedules;
    } catch (e) {
      debugPrint('Ошибка при получении расписания: $e');
      throw Exception('Ошибка при получении расписания: $e');
    }
  }

  // Метод для получения расписания по ФИО преподователя
  Future<List<Map<String, dynamic>>?> getScheduleForFullnameTeacher(String fullName) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('fullNameTeacher', isEqualTo: fullName)
          .get();

      List<Map<String, dynamic>> schedules = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return schedules;
    } catch (e) {
      debugPrint('Ошибка при получении расписания: $e');
      throw Exception('Ошибка при получении расписания: $e');
    }
  }

  // Метод для сохранения статуса пользователей в Firestore.
  // Пустой статус = «не отмечен», такая запись удаляется.
  Future<void> saveUserStatusToFirestore(
      String userGroup, String subject, String date, DateTime classTime, List<UserApp> users, Map<String, String> userStatus) async {
    for (var user in users) {
      final ref = _firestore
          .collection('magazine')
          .doc(userGroup)
          .collection(subject)
          .doc(date)
          .collection(classTime.toString())
          .doc(user.email);
      final status = userStatus[user.email] ?? '';
      if (status.isEmpty) {
        await ref.delete();
      } else {
        await ref.set({'status': status});
      }
    }
  }

  // Метод для загрузки статуса пользователей из Firestore
  Future<Map<String, String>> loadUserStatusFromFirestore(String userGroup, String subject, DateTime classTime, List<UserApp> users) async {
    Map<String, String> userStatus = {};
    try {
      final date = classTime.toString().split(' ')[0].replaceAll('-', ' ');
      final classTimeStr = classTime.toString();

      for (var user in users) {
        var doc = await _firestore
            .collection('magazine')
            .doc(userGroup)
            .collection(subject)
            .doc(date)
            .collection(classTimeStr)
            .doc(user.email)
            .get();

        // Нет записи — студент ещё не отмечен (не отсканировал QR)
        if (doc.exists) {
          userStatus[user.email] = doc.data()?['status'] ?? '';
        } else {
          userStatus[user.email] = '';
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке данных о посещаемости: $e');
    }
    return userStatus;
  }

  // ===================== Администратор =====================

  // Все пользователи вместе с uid
  Future<List<UserApp>> getAllUsersWithIds() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserApp.fromMap(doc.data(), uid: doc.id)).toList();
  }

  Future<void> updateUserRoleAndGroup(String uid, String rule, String group) async {
    await _firestore.collection('users').doc(uid).update({'rule': rule, 'group': group});
  }

  // ---- Группы: groups/{название} ----
  Future<List<String>> getGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    final groups = snapshot.docs.map((doc) => doc.id).toList();
    groups.sort();
    return groups;
  }

  // false, если такая группа уже есть
  Future<bool> addGroup(String name) async {
    final ref = _firestore.collection('groups').doc(name);
    if ((await ref.get()).exists) return false;
    await ref.set({'name': name});
    return true;
  }

  Future<void> deleteGroup(String name) async {
    await _firestore.collection('groups').doc(name).delete();
  }

  // ---- Предметы: subjects/{id} ----
  Future<List<Subject>> getSubjects() async {
    final snapshot = await _firestore.collection('subjects').get();
    final subjects = snapshot.docs
        .map((doc) => Subject(id: doc.id, title: doc.data()['title'] ?? ''))
        .toList();
    subjects.sort((a, b) => a.title.compareTo(b.title));
    return subjects;
  }

  Future<void> addSubject(String title) async {
    await _firestore.collection('subjects').add({'title': title});
  }

  Future<void> deleteSubject(String id) async {
    await _firestore.collection('subjects').doc(id).delete();
  }

  // ---- Предмет у группы: group_subjects/{id} ----
  Future<List<GroupSubject>> getGroupSubjects(String group) async {
    final snapshot = await _firestore
        .collection('group_subjects')
        .where('group', isEqualTo: group)
        .get();
    return snapshot.docs.map((doc) => GroupSubject.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<GroupSubject>> getGroupSubjectsForTeacher(String teacherUid) async {
    final snapshot = await _firestore
        .collection('group_subjects')
        .where('teacherUid', isEqualTo: teacherUid)
        .get();
    return snapshot.docs.map((doc) => GroupSubject.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addGroupSubject(GroupSubject groupSubject) async {
    await _firestore.collection('group_subjects').add(groupSubject.toMap());
  }

  Future<void> deleteGroupSubject(String id) async {
    await _firestore.collection('group_subjects').doc(id).delete();
  }

  // ---- Шаблон расписания: schedule_templates/{группа} ----
  Future<ScheduleTemplate> getScheduleTemplate(String group) async {
    final doc = await _firestore.collection('schedule_templates').doc(group).get();
    return ScheduleTemplate.fromMap(group, doc.data());
  }

  Future<void> saveScheduleTemplate(ScheduleTemplate template) async {
    await _firestore.collection('schedule_templates').doc(template.group).set(template.toMap());
  }

  // ---- Конкретные занятия: schedules/{id} ----
  Future<List<SubjectSchedule>> getLessonsForGroup(String group) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('group', isEqualTo: group)
        .get();
    return snapshot.docs.map((doc) => SubjectSchedule.fromMap(doc.data(), id: doc.id)).toList();
  }

  Future<List<SubjectSchedule>> getLessonsForTeacher(String teacherUid) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('teacherUid', isEqualTo: teacherUid)
        .get();
    return snapshot.docs.map((doc) => SubjectSchedule.fromMap(doc.data(), id: doc.id)).toList();
  }

  Future<void> deleteLesson(String id) async {
    await _firestore.collection('schedules').doc(id).delete();
  }

  // Заполняет schedules по шаблону с даты [from] до конца семестра.
  // Будущие занятия группы (с [from]) удаляются и создаются заново,
  // прошедшие не трогаются, чтобы не потерять журнал. Возвращает число созданных занятий.
  Future<int> generateSchedule(ScheduleTemplate template, DateTime from) async {
    final start = template.semesterStart!;
    final end = template.semesterEnd!;
    final fromDay = DateTime(from.year, from.month, from.day);
    var day = start.isAfter(fromDay) ? DateTime(start.year, start.month, start.day) : fromDay;

    final ops = <void Function(WriteBatch)>[];

    // Удаляем будущие занятия группы
    final existing = await _firestore
        .collection('schedules')
        .where('group', isEqualTo: template.group)
        .get();
    for (final doc in existing.docs) {
      final classTime = DateTime.tryParse(doc.data()['classTime'] ?? '');
      if (classTime != null && !classTime.isBefore(fromDay)) {
        ops.add((batch) => batch.delete(doc.reference));
      }
    }

    // Создаём занятия на каждый день до конца семестра
    var created = 0;
    while (!day.isAfter(end)) {
      final week = template.weekNumberFor(day);
      for (final lesson in template.lessons) {
        if (lesson.week != week || lesson.weekday != day.weekday) continue;
        final t = pairStartTimes[lesson.pair - 1];
        final classTime = DateTime(day.year, day.month, day.day, t[0], t[1]);
        final ref = _firestore.collection('schedules').doc();
        final data = {
          'titleSubject': lesson.subjectTitle,
          'typeActivity': lesson.typeActivity,
          'fullNameTeacher': lesson.teacherName,
          'teacherUid': lesson.teacherUid,
          'group': template.group,
          'subgroup': lesson.subgroup,
          'numberAudit': lesson.numberAudit,
          'classTime': classTime.toIso8601String(),
          'pair': lesson.pair,
        };
        ops.add((batch) => batch.set(ref, data));
        created++;
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }

    // В одном batch не больше 500 операций
    for (var i = 0; i < ops.length; i += 400) {
      final batch = _firestore.batch();
      for (final op in ops.skip(i).take(400)) {
        op(batch);
      }
      await batch.commit();
    }
    return created;
  }
}
