import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/view/hub/model/services/magazine/tag_user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TagUserView extends StatelessWidget {
  final SubjectSchedule subject;

  const TagUserView({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TagUserModel>(
      create: (context) => TagUserModel(subject),
      child: _SubjectDetailWidget(),
    );
  }
}

class _SubjectDetailWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TagUserModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(model.subject.titleSubject),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить отметки',
            onPressed: model.isLoading ? null : model.refresh,
          ),
        ],
      ),
      body: model.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: model.refresh,
              child: ListView.builder(
                // Сверху информация о паре и сводка, дальше студенты
                itemCount: model.users.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return const Column(children: [InfoSubject(), AttendanceSummary()]);
                  }
                  return TagUserWidget(user: model.users[index - 1]);
                },
              ),
            ),
      floatingActionButton: model.canEdit && model.hasChanges
          ? FloatingActionButton.extended(
              onPressed: model.isSaving ? null : () => model.saveUserStatus(context),
              icon: Icon(Icons.send_outlined),
              label: Text('Сохранить'),
            )
          : null,
    );
  }
}

class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TagUserModel>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              Text('Был: ${model.countOf('+')}', style: TextStyle(color: Colors.green)),
              Text('Не был: ${model.countOf('Н')}', style: TextStyle(color: Colors.red)),
              Text('Уваж.: ${model.countOf('У')}', style: TextStyle(color: Colors.blue)),
              Text('Не отмечен: ${model.countOf('')}', style: TextStyle(color: Colors.grey)),
            ],
          ),
          if (!model.canEdit)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Отметки ставит староста или QR-код преподавателя',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

class TagUserWidget extends StatelessWidget {
  final UserApp user;

  const TagUserWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TagUserModel>(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${user.surname} ${user.name}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            model.canEdit
                ? _buildButtons(model, user.email)
                : _buildStatusBadge(model.userStatus[user.email] ?? ''),
          ],
        ),
      ),
    );
  }

  static Color _colorOf(String status) {
    switch (status) {
      case '+':
        return Colors.green;
      case 'Н':
        return Colors.red;
      case 'У':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Для студентов — только просмотр отметки
  Widget _buildStatusBadge(String status) {
    final color = _colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(status.isEmpty ? '—' : status, style: TextStyle(color: color, fontSize: 16)),
    );
  }

  Widget _buildButtons(TagUserModel model, String userId) {
    return Row(
      children: [
        for (final status in TagUserModel.statuses)
          _buildButton(status, model, userId, _colorOf(status)),
      ],
    );
  }

  Widget _buildButton(
      String label, TagUserModel model, String userId, Color color) {
    final selected = model.userStatus[userId] == label;
    return GestureDetector(
      onTap: () {
        model.updateUserStatus(userId, label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(label, style: TextStyle(color: selected ? color : null, fontSize: 16)),
      ),
    );
  }
}

class InfoSubject extends StatelessWidget {
  const InfoSubject({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TagUserModel>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Преподаватель: ${model.subject.fullNameTeacher}',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'Тип занятия: ${model.subject.typeActivity}',
            style: TextStyle(fontSize: 18),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Аудитория: ${model.subject.numberAudit} ',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(model.subject.classTime)}',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          Text(
            'Подгруппа: ${model.subject.subgroup}',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
