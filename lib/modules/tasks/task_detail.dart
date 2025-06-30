import 'package:flutter/material.dart';
import 'task_model.dart';
import 'task_helpers.dart';

class TaskDetail extends StatelessWidget {
  final Task task;
  const TaskDetail({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Açıklama:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 32),
            Row(
              children: [
                const Text("Durum: "),
                Icon(
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
                Text(" ${statusText(task.status)}"),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Tarih: ${task.date.day}.${task.date.month}.${task.date.year}",
            ),
          ],
        ),
      ),
    );
  }
}
