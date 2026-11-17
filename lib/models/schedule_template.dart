// Двухнедельный шаблон расписания группы.
// Хранится одним документом schedule_templates/{группа}.

// Время начала пар (часы, минуты)
const List<List<int>> pairStartTimes = [
  [9, 0],
  [10, 40],
  [12, 40],
  [14, 20],
  [16, 20],
  [18, 0],
  [19, 40],
];

const List<String> weekdayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
const List<String> activityTypes = ['Лекция', 'Практика', 'Лабораторная'];
const List<String> subgroups = ['Вся группа', '1', '2'];

String pairTimeText(int pair) {
  final t = pairStartTimes[pair - 1];
  return '${t[0]}:${t[1].toString().padLeft(2, '0')}';
}

class TemplateLesson {
  final int week; // 1 или 2
  final int weekday; // 1 = понедельник ... 6 = суббота
  final int pair; // 1..7
  final String groupSubjectId;
  final String subjectTitle;
  final String typeActivity;
  final int numberAudit;
  final String subgroup;
  final String teacherUid;
  final String teacherName;

  TemplateLesson({
    required this.week,
    required this.weekday,
    required this.pair,
    required this.groupSubjectId,
    required this.subjectTitle,
    required this.typeActivity,
    required this.numberAudit,
    required this.subgroup,
    required this.teacherUid,
    required this.teacherName,
  });

  factory TemplateLesson.fromMap(Map<String, dynamic> doc) {
    return TemplateLesson(
      week: doc['week'] ?? 1,
      weekday: doc['weekday'] ?? 1,
      pair: doc['pair'] ?? 1,
      groupSubjectId: doc['groupSubjectId'] ?? '',
      subjectTitle: doc['subjectTitle'] ?? '',
      typeActivity: doc['typeActivity'] ?? '',
      numberAudit: doc['numberAudit'] ?? 0,
      subgroup: doc['subgroup'] ?? '',
      teacherUid: doc['teacherUid'] ?? '',
      teacherName: doc['teacherName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'weekday': weekday,
      'pair': pair,
      'groupSubjectId': groupSubjectId,
      'subjectTitle': subjectTitle,
      'typeActivity': typeActivity,
      'numberAudit': numberAudit,
      'subgroup': subgroup,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
    };
  }
}

class ScheduleTemplate {
  final String group;
  DateTime? semesterStart;
  DateTime? semesterEnd;
  List<TemplateLesson> lessons;

  ScheduleTemplate({
    required this.group,
    this.semesterStart,
    this.semesterEnd,
    List<TemplateLesson>? lessons,
  }) : lessons = lessons ?? [];

  factory ScheduleTemplate.fromMap(String group, Map<String, dynamic>? doc) {
    if (doc == null) return ScheduleTemplate(group: group);
    return ScheduleTemplate(
      group: group,
      semesterStart: doc['semesterStart'] != null ? DateTime.parse(doc['semesterStart']) : null,
      semesterEnd: doc['semesterEnd'] != null ? DateTime.parse(doc['semesterEnd']) : null,
      lessons: ((doc['lessons'] ?? []) as List)
          .map((e) => TemplateLesson.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semesterStart': semesterStart?.toIso8601String(),
      'semesterEnd': semesterEnd?.toIso8601String(),
      'lessons': lessons.map((e) => e.toMap()).toList(),
    };
  }

  // Неделя 1 — та, в которую попадает начало семестра, дальше чередуются
  int weekNumberFor(DateTime date) {
    final startMonday = _monday(semesterStart!);
    final weeks = _monday(date).difference(startMonday).inDays ~/ 7;
    return weeks % 2 == 0 ? 1 : 2;
  }

  static DateTime _monday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
