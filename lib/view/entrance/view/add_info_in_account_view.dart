import 'package:attendance_check/models/user_app.dart';
import 'package:attendance_check/utils/phone_input_formatter.dart';
import 'package:attendance_check/view/entrance/model/add_info_in_account_model.dart';
import 'package:attendance_check/view/entrance/widgets/widget_button_app.dart';
import 'package:attendance_check/view/entrance/widgets/widget_text_field_add_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance_check/services/firebase_service.dart';

class AddInfoInAccountView extends StatelessWidget {
  const AddInfoInAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddInfoInAccountModel>(
      create: (context) => AddInfoInAccountModel(UserApp(), FirebaseService()),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AddInfoInAccountModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавьте информацию'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFieldAddInfo(
                  hint: model.email, enabled: false, onChanged: null),
              const SizedBox(height: 16),
              TextFieldAddInfo(
                  hint: 'Фамилия',
                  enabled: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: model.setSurname),
              const SizedBox(height: 16),
              TextFieldAddInfo(
                  hint: 'Имя',
                  enabled: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: model.setName),
              const SizedBox(height: 16),
              TextFieldAddInfo(
                  hint: 'Отчество (если есть)',
                  enabled: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: model.setPatronymic),
              const SizedBox(height: 16),
              TextFieldAddInfo(
                  hint: '+7 952 956 17 97',
                  enabled: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  onChanged: model.setPhoneNumber),
              const SizedBox(height: 16),
              const Text(
                'Роль и группу назначит администратор',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Center(
                child: ButtonApp(
                  text: "Сохранить",
                  onChanged: model.isSaving ? null : () => model.validateAndSave(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}