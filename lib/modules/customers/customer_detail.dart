import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tasks/task_model.dart';
import 'customer_model.dart';
import 'work_entry_model.dart';
import 'other_work_entry_model.dart';
import 'work_entry_screen.dart';
import 'customer_material_model.dart';
import 'customer_material_form.dart'; // <-- Malzeme formunu import et

// Malzeme formu ve tablosu burada tanımlıysa tekrar eklemene gerek yok.
// Eğer ayrı bir dosyada ise, yukarıdaki gibi import etmelisin.

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  final List<Task> allTasks;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.allTasks,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  List<Task> get customerTasks =>
      widget.allTasks.where((t) => t.customerId == widget.customer.id).toList();

  void _addTask(Task newTask) {
    setState(() {
      widget.allTasks.add(newTask);
    });
  }

  Stream<List<WorkEntry>> _hourlyEntriesStream() {
    if (widget.customer.id.isEmpty) {
      return const Stream<List<WorkEntry>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('hourly_work_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => WorkEntry.fromJson(
                  doc.data() as Map<String, dynamic>,
                  docId: doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<List<OtherWorkEntry>> _otherEntriesStream() {
    if (widget.customer.id.isEmpty) {
      return const Stream<List<OtherWorkEntry>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('other_work_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => OtherWorkEntry.fromJson(
                  doc.data() as Map<String, dynamic>,
                  docId: doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    if (customer.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Müşteri Detay")),
        body: const Center(
          child: Text(
            "Geçersiz müşteri! Lütfen önce müşteri oluşturun.",
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${customer.name} Detay")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(customer.name),
            subtitle: Text("Müşteri ID: ${customer.id}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.work_outline),
                  label: const Text("İşçilik / Çalışma Kalemleri"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkEntryScreen(customer: customer),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2),
                  label: const Text("Malzeme"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: Text("${customer.name} Malzemeler"),
                          ),
                          body: CustomerMaterialForm(customerId: customer.id),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Son Eklenen Saatlik İşçilikler",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 120,
            child: StreamBuilder<List<WorkEntry>>(
              stream: _hourlyEntriesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return const Center(child: Text("Saatlik işçilik yok."));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    final e = entries[idx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.description ?? "Açıklama yok",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (e.date != null)
                              Text(
                                "Tarih: ${e.date.day}.${e.date.month}.${e.date.year}",
                              ),
                            if (e.workCost != null)
                              Text(
                                "Tutar: ${e.workCost!.toStringAsFixed(2)} ₺",
                              ),
                            if (e.workLocation != null)
                              Text("Yer: ${e.workLocation}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Son Eklenen Tablo Kalemleri",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 120,
            child: StreamBuilder<List<OtherWorkEntry>>(
              stream: _otherEntriesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return const Center(child: Text("Tablo kalemi yok."));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    final e = entries[idx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.description ?? "Açıklama yok",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (e.date != null)
                              Text(
                                "Tarih: ${e.date.day}.${e.date.month}.${e.date.year}",
                              ),
                            if (e.totalCost != null)
                              Text(
                                "Tutar: ${e.totalCost!.toStringAsFixed(2)} ₺",
                              ),
                            if (e.workLocation != null)
                              Text("Yer: ${e.workLocation}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          // ------ Malzeme Alanı ------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Malzemeler",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomerMaterialForm(
              customerId: customer.id,
              onMaterialAdded: () => setState(() {}),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Görevler",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: customerTasks.isEmpty
                ? const Center(child: Text("Bu müşteriye ait görev yok."))
                : ListView.builder(
                    itemCount: customerTasks.length,
                    itemBuilder: (context, i) {
                      final task = customerTasks[i];
                      return ListTile(
                        leading: Icon(
                          task.status == TaskStatus.done
                              ? Icons.check_circle
                              : task.status == TaskStatus.inProgress
                              ? Icons.timelapse
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Text(
                          "${task.date.day}.${task.date.month}.${task.date.year}",
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(
              builder: (_) => TaskForm(initialCustomerId: customer.id),
            ),
          );
          if (newTask != null) _addTask(newTask);
        },
        tooltip: "Bu müşteriye görev ekle",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskForm extends StatelessWidget {
  final String? initialCustomerId;
  const TaskForm({super.key, this.initialCustomerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görev Ekle')),
      body: Center(child: Text('Seçili müşteri: $initialCustomerId')),
    );
  }
}
