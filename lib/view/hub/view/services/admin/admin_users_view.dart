import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/view/hub/model/services/admin/admin_users_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminUsersModel>(
      create: (context) => AdminUsersModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminUsersModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: model.load),
        ],
      ),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск по ФИО, почте или группе',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: model.setSearch,
                  ),
                ),
                SwitchListTile(
                  title: Text('Только незаполненные (${model.incompleteCount})'),
                  value: model.onlyIncomplete,
                  onChanged: model.setOnlyIncomplete,
                ),
                Expanded(
                  child: model.users.isEmpty
                      ? const Center(child: Text('Пользователей нет'))
                      : ListView.builder(
                          itemCount: model.users.length,
                          itemBuilder: (context, index) => AdminUserCard(user: model.users[index]),
                        ),
                ),
              ],
            ),
    );
  }
}

class AdminUserCard extends StatelessWidget {
  final UserApp user;

  const AdminUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final incomplete = AdminUsersModel.isIncomplete(user);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: incomplete ? Colors.orange : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => showDialog(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: Provider.of<AdminUsersModel>(context, listen: false),
            child: EditUserDialog(user: user),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName.isEmpty ? '(ФИО не заполнено)' : user.fullName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('${user.email}   ${user.phoneNumber}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _StatusChip(
                    label: user.hasRule ? user.rule : 'Роль не назначена',
                    ok: user.hasRule,
                  ),
                  if (!user.needsGroup)
                    const _StatusChip(label: 'Группа не нужна', ok: true)
                  else
                    _StatusChip(
                      label: user.group.isEmpty ? 'Группа не указана' : user.group,
                      ok: user.group.isNotEmpty,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, color: color.shade800)),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final UserApp user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  String? _rule;
  String? _group;

  @override
  void initState() {
    super.initState();
    _rule = widget.user.hasRule ? widget.user.rule : null;
    _group = widget.user.group.isEmpty ? null : widget.user.group;
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AdminUsersModel>(context);
    final needsGroup = _rule == null || (UserApp()..setRule(_rule!)).needsGroup;
    // Если группа пользователя удалена из справочника, всё равно показываем её
    final groups = {...model.groups, if (_group != null) _group!}.toList()..sort();

    return AlertDialog(
      title: Text(widget.user.fullName.isEmpty ? widget.user.email : widget.user.fullName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _rule,
            decoration: const InputDecoration(labelText: 'Роль'),
            items: UserApp.allRules
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _rule = v),
          ),
          const SizedBox(height: 12),
          if (needsGroup)
            DropdownButtonFormField<String>(
              initialValue: _group,
              decoration: const InputDecoration(labelText: 'Группа'),
              items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _group = v),
            )
          else
            const Text('Для этой роли группа не нужна'),
          if (needsGroup && model.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Сначала добавьте группы в разделе «Группы»',
                  style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: _rule == null
              ? null
              : () async {
                  await model.saveUser(context, widget.user, _rule!, _group ?? '');
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
