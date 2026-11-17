import 'package:attendance_check/models/subject.dart';
import 'package:attendance_check/view/hub/model/services/admin/admin_subjects_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSubjectsView extends StatelessWidget {
  const AdminSubjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminSubjectsModel>(
      create: (context) => AdminSubjectsModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminSubjectsModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Предметы'), centerTitle: true),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : model.subjects.isEmpty
              ? const Center(child: Text('Предметов пока нет. Нажмите «+», чтобы добавить'))
              : ListView.builder(
                  itemCount: model.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = model.subjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(subject.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, model, subject),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, model),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AdminSubjectsModel model) {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Новый предмет'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'Название предмета', errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final result = await model.addSubject(controller.text);
                if (result == null) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } else {
                  setState(() => error = result);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminSubjectsModel model, Subject subject) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить «${subject.title}»?'),
        content: const Text('Предмет пропадёт из справочника. Уже привязанные к группам '
            'предметы и расписание не изменятся.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              model.deleteSubject(subject);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
