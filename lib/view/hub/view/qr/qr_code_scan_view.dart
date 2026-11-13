import 'package:attendance_check/models/subject_schedule.dart';
import 'package:attendance_check/view/hub/model/qr/qr_code_model.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class QrCodeScanView extends StatelessWidget {
  const QrCodeScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QrCodeModel>(
      create: (context) => QrCodeModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Сканер'),
        centerTitle: true,
      ),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : model.isTeacher
              ? const ScheduleTeacherView()
              : const QrScannerView(),
    );
  }
}

class ScheduleTeacherView extends StatelessWidget {
  const ScheduleTeacherView({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CalendarWidget(),
          model.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ScheduleListWidget(),
                ),
        ],
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);

    return TableCalendar(
      locale: 'ru_RU',
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: model.focusedDay,
      calendarFormat: model.calendarFormat,
      onDaySelected: model.onDaySelected,
      selectedDayPredicate: (day) {
        return isSameDay(model.selectedDay, day);
      },
      headerStyle: const HeaderStyle(
        titleTextStyle: TextStyle(fontSize: 18),
        formatButtonTextStyle: TextStyle(fontSize: 18),
      ),
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(fontSize: 18),
        weekendTextStyle: TextStyle(fontSize: 18),
        selectedTextStyle: TextStyle(fontSize: 18),
        todayTextStyle: TextStyle(fontSize: 18),
      ),
      daysOfWeekHeight: 40,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 18),
        weekendStyle: TextStyle(fontSize: 18),
      ),
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {
        CalendarFormat.week: 'Неделя',
      },
      onFormatChanged: model.onFormatChanged,
    );
  }
}

class ScheduleListWidget extends StatelessWidget {
  const ScheduleListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);
    final filteredList = model.getSchedulesForDay(model.selectedDay);
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (BuildContext context, int index) {
        return ScheduleTeacherWidget(schedule: filteredList[index]);
      },
    );
  }
}

class ScheduleTeacherWidget extends StatelessWidget {
  final SubjectSchedule schedule;

  const ScheduleTeacherWidget({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);
    return GestureDetector(
      onTap: () => model.goQrGeneration(context, schedule),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${schedule.classTime.hour}:${schedule.classTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                schedule.titleSubject,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.meeting_room, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Аудитория: ${schedule.numberAudit}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Группа: ${schedule.group}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.group, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Подгруппа: ${schedule.subgroup}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
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

class QrScannerView extends StatelessWidget {
  const QrScannerView({super.key});
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<QrCodeModel>(context);

    if (model.scanMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              model.scanSuccess ? Icons.check_circle : Icons.error,
              color: model.scanSuccess ? Colors.green : Colors.red,
              size: 96,
            ),
            const SizedBox(height: 16),
            Text(
              model.scanMessage!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: model.resetScan,
              child: const Text('Сканировать снова'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Наведите камеру на QR-код преподавателя',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  model.onQrScanned(capture.barcodes.first.rawValue);
                },
              ),
              if (model.isProcessing) const CircularProgressIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}
