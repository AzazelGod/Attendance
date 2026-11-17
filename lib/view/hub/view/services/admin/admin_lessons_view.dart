import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/view/hub/model/services/admin/admin_lessons_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminLessonsView extends StatelessWidget {
  final String group;

  const AdminLessonsView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminLessonsModel>(
      create: (context) => AdminLessonsModel(group),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminLessonsModel>(context);
    final lessons = model.lessonsForSelectedDay();
    return Scaffold(
      appBar: AppBar(title: Text('Занятия ${model.group}'), centerTitle: true),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: model.focusedDay,
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {CalendarFormat.week: 'Неделя'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(model.selectedDay, day),
            onDaySelected: model.onDaySelected,
          ),
          const Divider(),
          Expanded(
            child: model.isLoading
                ? const Center(child: CircularProgressIndicator())
                : lessons.isEmpty
                    ? const Center(child: Text('В этот день занятий нет'))
                    : ListView.builder(
                        itemCount: lessons.length,
                        itemBuilder: (context, index) => _LessonTile(lesson: lessons[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final SubjectSchedule lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminLessonsModel>(context, listen: false);
    final time = '${lesson.classTime.hour}:${lesson.classTime.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        title: Text('$time  ${lesson.titleSubject}'),
        subtitle: Text('${lesson.typeActivity} · ауд. ${lesson.numberAudit} · ${lesson.fullNameTeacher}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Убрать пару в этот день',
          onPressed: () => showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Убрать пару?'),
              content: Text('«${lesson.titleSubject}» в $time будет удалена только в этот день.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    model.deleteLesson(lesson);
                  },
                  child: const Text('Убрать', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
