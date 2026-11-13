import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/view/hub/model/qr/qr_generation_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGenerationView extends StatelessWidget {
  final SubjectSchedule subject;

  const QrGenerationView({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QrGeneretionModel>(
      create: (context) => QrGeneretionModel(subject),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrGeneretionModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Генерация QR-кода'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.subject.titleSubject,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Группа: ${model.subject.group}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Белый фон, чтобы код читался и в тёмной теме
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: model.qrData,
                size: 300,
                version: QrVersions.auto,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Код обновляется каждые ${QrGeneretionModel.refreshInterval.inSeconds} секунд',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
