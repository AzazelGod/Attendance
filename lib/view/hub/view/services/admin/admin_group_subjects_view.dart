import 'package:attendance_check/models/discipline.dart';
import 'package:attendance_check/models/subject.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/view/hub/model/services/admin/admin_group_subjects_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Map<AssessmentType, String> assessmentNames = {
  AssessmentType.credit: 'Зачёт',
  AssessmentType.creditWithGrade: 'Зачёт с оценкой',
  AssessmentType.exam: 'Экзамен',
};

class AdminGroupSubjectsView extends StatelessWidget {
  final String group;

  const AdminGroupSubjectsView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminGroupSubjectsModel>(
      create: (context) => AdminGroupSubjectsModel(group),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminGroupSubjectsModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Предметы ${model.group}'), centerTitle: true),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : model.groupSubjects.isEmpty
              ? const Center(child: Text('У группы пока нет предметов'))
              : ListView.builder(
                  itemCount: model.groupSubjects.length,
                  itemBuilder: (context, index) {
                    final gs = model.groupSubjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: ListTile(
                        title: Text(gs.subjectTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${gs.teacherName}\n'
                            '${gs.hours} ч · ${assessmentNames[gs.assessmentType]}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => model.delete(gs),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: model.isLoading
            ? null
            : () => showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: model,
                    child: const AddGroupSubjectDialog(),
                  ),
                ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddGroupSubjectDialog extends StatefulWidget {
  const AddGroupSubjectDialog({super.key});

  @override
  State<AddGroupSubjectDialog> createState() => _AddGroupSubjectDialogState();
}

class _AddGroupSubjectDialogState extends State<AddGroupSubjectDialog> {
  Subject? _subject;
  UserApp? _teacher;
  AssessmentType _assessment = AssessmentType.exam;
  final _hours = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminGroupSubjectsModel>(context);
    return AlertDialog(
      title: const Text('Добавить предмет'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (model.subjects.isEmpty)
              const Text('Сначала добавьте предметы в разделе «Предметы»',
                  style: TextStyle(color: Colors.orange)),
            if (model.teachers.isEmpty)
              const Text('Нет пользователей с ролью «Преподаватель»',
                  style: TextStyle(color: Colors.orange)),
            DropdownButtonFormField<Subject>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Предмет'),
              items: model.subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.title)))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v),
            ),
            DropdownButtonFormField<UserApp>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Преподаватель'),
              items: model.teachers
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.fullName)))
                  .toList(),
              onChanged: (v) => setState(() => _teacher = v),
            ),
            TextField(
              controller: _hours,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Часов'),
            ),
            DropdownButtonFormField<AssessmentType>(
              initialValue: _assessment,
              decoration: const InputDecoration(labelText: 'Аттестация'),
              items: AssessmentType.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(assessmentNames[a]!)))
                  .toList(),
              onChanged: (v) => setState(() => _assessment = v!),
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
        ElevatedButton(
          onPressed: () async {
            final error = await model.add(
              subject: _subject,
              teacher: _teacher,
              hoursText: _hours.text,
              assessmentType: _assessment,
            );
            if (error == null) {
              if (context.mounted) Navigator.pop(context);
            } else {
              setState(() => _error = error);
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
