import 'package:attendance_check/models/group_subject.dart';
import 'package:attendance_check/models/schedule_template.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/view/hub/model/services/admin/admin_schedule_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminScheduleView extends StatelessWidget {
  const AdminScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminScheduleModel>(
      create: (context) => AdminScheduleModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminScheduleModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        centerTitle: true,
        actions: [
          if (model.template != null)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Занятия по дням',
              onPressed: () => model.goLessons(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: model.group,
              decoration: const InputDecoration(labelText: 'Группа', border: OutlineInputBorder()),
              items: model.groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (g) => model.selectGroup(g!),
            ),
          ),
          Expanded(
            child: model.isLoading
                ? const Center(child: CircularProgressIndicator())
                : model.template == null
                    ? const Center(child: Text('Выберите группу'))
                    : const _TemplateEditor(),
          ),
        ],
      ),
      bottomNavigationBar: model.template == null ? null : const _BottomButtons(),
    );
  }
}

class _TemplateEditor extends StatelessWidget {
  const _TemplateEditor();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminScheduleModel>(context);
    final t = model.template!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (model.groupSubjects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('У группы нет предметов. Добавьте их в разделе «Группы».',
                style: TextStyle(color: Colors.orange)),
          ),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'Начало семестра',
                date: t.semesterStart,
                onPicked: model.setSemesterStart,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateButton(
                label: 'Конец семестра',
                date: t.semesterEnd,
                onPicked: model.setSemesterEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 неделя')),
                  ButtonSegment(value: 2, label: Text('2 неделя')),
                ],
                selected: {model.week},
                onSelectionChanged: (s) => model.setWeek(s.first),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Скопировать в другую неделю',
              onPressed: () => _confirmCopy(context, model),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Неделя 1 — та, на которую приходится начало семестра',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        for (var weekday = 1; weekday <= weekdayNames.length; weekday++)
          _DayCard(weekday: weekday),
      ],
    );
  }

  void _confirmCopy(BuildContext context, AdminScheduleModel model) {
    final other = model.week == 1 ? 2 : 1;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Скопировать неделю ${model.week} в неделю $other?'),
        content: Text('Все пары недели $other будут заменены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              model.copyWeekToOther();
            },
            child: const Text('Скопировать'),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;

  const _DateButton({required this.label, required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
        );
        if (picked != null) onPicked(picked);
      },
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(date == null ? 'не выбрано' : DateFormat('dd.MM.yyyy').format(date!)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int weekday;

  const _DayCard({required this.weekday});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminScheduleModel>(context);
    final lessons = model.lessonsFor(weekday);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              title: Text(weekdayNames[weekday - 1],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Добавить пару',
                onPressed: model.groupSubjects.isEmpty
                    ? null
                    : () => showDialog(
                          context: context,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: model,
                            child: AddLessonDialog(weekday: weekday),
                          ),
                        ),
              ),
            ),
            if (lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Пар нет', style: TextStyle(color: Colors.grey)),
              ),
            for (final lesson in lessons)
              ListTile(
                dense: true,
                leading: CircleAvatar(radius: 14, child: Text('${lesson.pair}')),
                title: Text('${pairTimeText(lesson.pair)}  ${lesson.subjectTitle}'),
                subtitle: Text('${lesson.typeActivity} · ауд. ${lesson.numberAudit} · '
                    '${lesson.teacherName}'
                    '${lesson.subgroup == subgroups[0] ? '' : ' · подгр. ${lesson.subgroup}'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => model.removeLesson(lesson),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddLessonDialog extends StatefulWidget {
  final int weekday;

  const AddLessonDialog({super.key, required this.weekday});

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  int _pair = 1;
  GroupSubject? _groupSubject;
  String? _teacherUid;
  String _type = activityTypes[0];
  String _subgroup = subgroups[0];
  final _audit = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminScheduleModel>(context);
    return AlertDialog(
      title: Text('${weekdayNames[widget.weekday - 1]}, неделя ${model.week}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _pair,
              decoration: const InputDecoration(labelText: 'Пара'),
              items: [
                for (var p = 1; p <= pairStartTimes.length; p++)
                  DropdownMenuItem(value: p, child: Text('$p пара — ${pairTimeText(p)}')),
              ],
              onChanged: (v) => setState(() => _pair = v!),
            ),
            DropdownButtonFormField<GroupSubject>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Предмет'),
              items: model.groupSubjects
                  .map((gs) => DropdownMenuItem(value: gs, child: Text(gs.subjectTitle)))
                  .toList(),
              // Преподаватель подставляется из привязки предмета к группе
              onChanged: (v) => setState(() {
                _groupSubject = v;
                _teacherUid = v?.teacherUid;
              }),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey(_groupSubject?.id),
              isExpanded: true,
              initialValue: model.teachers.any((t) => t.uid == _teacherUid) ? _teacherUid : null,
              decoration: const InputDecoration(labelText: 'Преподаватель'),
              items: model.teachers
                  .map((t) => DropdownMenuItem(value: t.uid, child: Text(t.fullName)))
                  .toList(),
              onChanged: (v) => setState(() => _teacherUid = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Тип занятия'),
              items: activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            TextField(
              controller: _audit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Аудитория (номер)'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _subgroup,
              decoration: const InputDecoration(labelText: 'Подгруппа'),
              items: subgroups.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _subgroup = v!),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(onPressed: () => _add(model), child: const Text('Добавить')),
      ],
    );
  }

  void _add(AdminScheduleModel model) {
    final audit = int.tryParse(_audit.text.trim());
    UserApp? teacher;
    for (final t in model.teachers) {
      if (t.uid == _teacherUid) teacher = t;
    }
    String? error;
    if (_groupSubject == null) {
      error = 'Выберите предмет';
    } else if (teacher == null) {
      error = 'Выберите преподавателя';
    } else if (audit == null) {
      error = 'Укажите номер аудитории';
    } else if (model.isPairBusy(widget.weekday, _pair, _subgroup)) {
      error = 'Эта пара уже занята';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    model.addLesson(TemplateLesson(
      week: model.week,
      weekday: widget.weekday,
      pair: _pair,
      groupSubjectId: _groupSubject!.id,
      subjectTitle: _groupSubject!.subjectTitle,
      typeActivity: _type,
      numberAudit: audit!,
      subgroup: _subgroup,
      teacherUid: teacher!.uid,
      teacherName: teacher.shortName,
    ));
    Navigator.pop(context);
  }
}

class _BottomButtons extends StatelessWidget {
  const _BottomButtons();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminScheduleModel>(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: model.isSaving || !model.hasChanges
                    ? null
                    : () async => _show(context, await model.saveTemplate()),
                child: const Text('Сохранить шаблон'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: model.isSaving ? null : () => _confirmGenerate(context, model),
                child: model.isSaving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Заполнить семестр'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmGenerate(BuildContext context, AdminScheduleModel model) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Заполнить расписание?'),
        content: Text('Занятия группы ${model.group} с сегодняшнего дня до конца семестра '
            'будут созданы заново по шаблону. Ручные удаления пар на будущие дни сбросятся. '
            'Прошедшие занятия и журнал не изменятся.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final message = await model.generate();
              if (context.mounted) _show(context, message);
            },
            child: const Text('Заполнить'),
          ),
        ],
      ),
    );
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
