import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_model.dart';
import 'task_form.dart';
import '../customers/customer_model.dart';
import 'task_helpers.dart';

class TaskCalendar extends StatefulWidget {
  final List<Task> tasks;
  final List<Customer> customers;
  const TaskCalendar({super.key, required this.tasks, required this.customers});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Task>> get _tasksByDay {
    Map<DateTime, List<Task>> map = {};
    for (final task in widget.tasks) {
      final day = DateTime(task.date.year, task.date.month, task.date.day);
      map.putIfAbsent(day, () => []).add(task);
    }
    return map;
  }

  List<Task> _getTasksForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _tasksByDay[key] ?? [];
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    if (_getTasksForDay(selectedDay).isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskForm(initialDate: selectedDay)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              _selectedDay != null &&
              day.year == _selectedDay!.year &&
              day.month == _selectedDay!.month &&
              day.day == _selectedDay!.day,
          eventLoader: _getTasksForDay,
          onDaySelected: _onDaySelected,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedDay != null)
          ..._getTasksForDay(_selectedDay!).map(
            (task) => Card(
              child: ListTile(
                leading: Icon(
                  task.status == TaskStatus.done
                      ? Icons.check_circle
                      : task.status == TaskStatus.inProgress
                      ? Icons.timelapse
                      : Icons.radio_button_unchecked,
                  color: task.status == TaskStatus.done
                      ? Colors.green
                      : task.status == TaskStatus.inProgress
                      ? Colors.orange
                      : Colors.grey,
                ),
                title: Text(task.title),
                subtitle: Text(
                  "${task.description}\nMüşteri: ${getCustomerName(task.customerId, widget.customers)}",
                ),
              ),
            ),
          ),
        if (_selectedDay != null && _getTasksForDay(_selectedDay!).isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Bu gün için görev yok. Tıklayarak ekleyebilirsiniz."),
          ),
      ],
    );
  }
}
