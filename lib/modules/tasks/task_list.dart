import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';
import 'task_form.dart';
import 'calendar.dart';
import '../customers/customer_model.dart';
import 'task_helpers.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList>
    with SingleTickerProviderStateMixin {
  TaskStatus? filter;
  String? selectedCustomerId;
  String search = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> filterTasks(List<Task> tasks) {
    var result = tasks;
    if (filter != null)
      result = result.where((t) => t.status == filter).toList();
    if (selectedCustomerId != null)
      result = result.where((t) => t.customerId == selectedCustomerId).toList();
    if (search.isNotEmpty) {
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(search.toLowerCase()) ||
                t.description.toLowerCase().contains(search.toLowerCase()),
          )
          .toList();
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Görevler"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Liste"),
            Tab(icon: Icon(Icons.calendar_today), text: "Takvim"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (ctx, taskSnap) {
          if (taskSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks =
              taskSnap.data?.docs
                  .map(
                    (d) => Task.fromMap(
                      d.data() as Map<String, dynamic>,
                      documentId: d.id,
                    ),
                  )
                  .toList() ??
              [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('customers')
                .snapshots(),
            builder: (ctx, custSnap) {
              if (custSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final customers =
                  custSnap.data?.docs.map((d) {
                    final map = d.data() as Map<String, dynamic>;
                    map['id'] = d.id;
                    return Customer.fromMap(map);
                  }).toList() ??
                  [];

              final filtered = filterTasks(tasks);

              return TabBarView(
                controller: _tabController,
                children: [
                  // Liste görünümü
                  Column(
                    children: [
                      // Arama kutusu
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Görev Ara",
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            fillColor: colorScheme.surfaceVariant,
                            filled: true,
                          ),
                          onChanged: (v) => setState(() => search = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          DropdownButton<String?>(
                            value: selectedCustomerId,
                            hint: const Text("Müşteri"),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("Tümü"),
                              ),
                              ...customers.map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => selectedCustomerId = val),
                          ),
                          DropdownButton<TaskStatus?>(
                            value: filter,
                            hint: const Text("Durum"),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text("Tümü"),
                              ),
                              DropdownMenuItem(
                                value: TaskStatus.todo,
                                child: Text("Beklemede"),
                              ),
                              DropdownMenuItem(
                                value: TaskStatus.inProgress,
                                child: Text("Devam Ediyor"),
                              ),
                              DropdownMenuItem(
                                value: TaskStatus.done,
                                child: Text("Yapıldı"),
                              ),
                            ],
                            onChanged: (val) => setState(() => filter = val),
                          ),
                        ],
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text("Hiç görev yok."))
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final task = filtered[i];
                                  final isToday =
                                      DateTime.now().year == task.date.year &&
                                      DateTime.now().month == task.date.month &&
                                      DateTime.now().day == task.date.day;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      tileColor: isToday
                                          ? colorScheme.secondaryContainer
                                          : null,
                                      leading: Icon(
                                        task.status == TaskStatus.done
                                            ? Icons.check_circle
                                            : task.status ==
                                                  TaskStatus.inProgress
                                            ? Icons.timelapse
                                            : Icons.radio_button_unchecked,
                                        color: task.status == TaskStatus.done
                                            ? Colors.green
                                            : task.status ==
                                                  TaskStatus.inProgress
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                      title: Text(task.title),
                                      subtitle: Text(
                                        "${task.description}\nMüşteri: ${getCustomerName(task.customerId, customers)}\nDurum: ${statusText(task.status)}",
                                      ),
                                      isThreeLine: true,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final updated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TaskForm(initialTask: task),
                                            ),
                                          );
                                          // Firestore ile anlık güncelleneceği için ek işlem yok
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  // Takvim görünümü
                  TaskCalendar(tasks: tasks, customers: customers),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskForm()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Yeni Görev"),
      ),
    );
  }
}
