import 'package:attendance_check/view/hub/model/services/admin/admin_groups_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminGroupsView extends StatelessWidget {
  const AdminGroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminGroupsModel>(
      create: (context) => AdminGroupsModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminGroupsModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Группы'), centerTitle: true),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : model.groups.isEmpty
              ? const Center(child: Text('Групп пока нет. Нажмите «+», чтобы добавить'))
              : ListView.builder(
                  itemCount: model.groups.length,
                  itemBuilder: (context, index) {
                    final group = model.groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(group, style: const TextStyle(fontSize: 18)),
                        subtitle: const Text('Нажмите, чтобы настроить предметы'),
                        onTap: () => model.goGroupSubjects(context, group),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, model, group),
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

  void _showAddDialog(BuildContext context, AdminGroupsModel model) {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Новая группа'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: 'БИСО-01-23', errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final result = await model.addGroup(controller.text);
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

  void _confirmDelete(BuildContext context, AdminGroupsModel model, String group) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить группу $group?'),
        content: const Text('Пользователи, предметы и расписание группы останутся в базе, '
            'но группу больше нельзя будет выбрать.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              model.deleteGroup(group);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
