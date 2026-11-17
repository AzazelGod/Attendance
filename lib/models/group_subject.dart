import 'package:attendance_check/models/discipline.dart';

// Привязка предмета к группе: кто ведёт по умолчанию, часы и тип аттестации.
// Хранится в коллекции group_subjects.
class GroupSubject {
  final String id;
  final String group;
  final String subjectId;
  final String subjectTitle;
  final String teacherUid;
  final String teacherName;
  final int hours;
  final AssessmentType assessmentType;

  GroupSubject({
    this.id = '',
    required this.group,
    required this.subjectId,
    required this.subjectTitle,
    required this.teacherUid,
    required this.teacherName,
    required this.hours,
    required this.assessmentType,
  });

  factory GroupSubject.fromMap(String id, Map<String, dynamic> doc) {
    return GroupSubject(
      id: id,
      group: doc['group'] ?? '',
      subjectId: doc['subjectId'] ?? '',
      subjectTitle: doc['subjectTitle'] ?? '',
      teacherUid: doc['teacherUid'] ?? '',
      teacherName: doc['teacherName'] ?? '',
      hours: doc['hours'] ?? 0,
      assessmentType: Discipline.assessmentTypeFromString(doc['assessmentType'] ?? 'exam'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group': group,
      'subjectId': subjectId,
      'subjectTitle': subjectTitle,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'hours': hours,
      'assessmentType': assessmentType.name,
    };
  }
}
