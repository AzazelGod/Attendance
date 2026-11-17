import 'package:attendance_check/view/hub/model/services/magazine/magazine_model.dart';
import 'package:attendance_check/view/hub/widgets/schedule_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class MagazineView extends StatelessWidget {
  const MagazineView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MagazineModel>(
      create: (context) => MagazineModel(),
      child: _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MagazineModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Журнал"),
        centerTitle: true,
        actions: [
          TextButton(onPressed: model.goToday, child: const Text('Сегодня')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const MagazineCalendarWidget(),
            const SizedBox(height: 8),
            Expanded(
              child: model.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const MagazineListWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class MagazineCalendarWidget extends StatelessWidget {
  const MagazineCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MagazineModel>(context);
    return TableCalendar(
      locale: 'ru_RU',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: model.focusedDay,
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {CalendarFormat.week: 'Неделя'},
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(model.selectedDay, day),
      onDaySelected: model.onDaySelected,
      onPageChanged: model.onPageChanged,
      // Точки под днями, в которые есть пары
      eventLoader: model.getSchedulesForDay,
      calendarStyle: const CalendarStyle(markersMaxCount: 1),
    );
  }
}

class MagazineListWidget extends StatelessWidget {
  const MagazineListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MagazineModel>(context);
    final lessons = model.getSchedulesForDay(model.selectedDay);
    if (lessons.isEmpty) {
      return const Center(child: Text('В этот день пар нет'));
    }
    return ListView.builder(
      itemCount: lessons.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () => model.goTagUserView(context, lessons[index]),
          child: ScheduleWidget(schedule: lessons[index]),
        );
      },
    );
  }
}
