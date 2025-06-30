import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tasks/task_model.dart';
import 'customer_model.dart';
import 'work_entry_model.dart';
import 'other_work_entry_model.dart';
import 'work_entry_screen.dart';
import 'customer_material_form.dart';
import 'customer_material_model.dart';

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

    // NULL GÜVENLİĞİ: Customer null veya id boş ise
    if (customer.id.isEmpty || customer.name.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Müşteri Detayı')),
        body: const Center(
          child: Text(
            'Geçersiz müşteri! Lütfen önce müşteri oluşturun.',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${customer.name} Detay")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Müşteri Başlık ve Aksiyonlar ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        customer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text('Müşteri ID: ${customer.id}'),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.work_outline),
                    label: const Text('İşçilik'),
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
                    label: const Text('Malzeme'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text("${customer.name} Malzemeler"),
                            ),
                            body: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomerMaterialForm(
                                customerId: customer.id,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 30),
              // --- İletişim Bilgileri ve Notlar için örnek alan ---
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: const Text('İletişim ve Diğer Bilgiler'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer.phone.isNotEmpty)
                        Text('Telefon: ${customer.phone}'),
                      if (customer.email.isNotEmpty)
                        Text('E-posta: ${customer.email}'),
                      if ((customer.address).isNotEmpty)
                        Text('Adres: ${customer.address}'),
                      if ((customer.notes ?? "").isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Not: ${customer.notes!}'),
                        ),
                    ],
                  ),
                ),
              ),
              // --- Saatlik İşçilikler ---
              Text(
                'Son Saatlik İşçilikler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: 130,
                child: StreamBuilder<List<WorkEntry>>(
                  stream: _hourlyEntriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Bir hata oluştu, lütfen tekrar deneyin.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final entries = snapshot.data!;
                    if (entries.isEmpty) {
                      return const Center(child: Text('Saatlik işçilik yok.'));
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
                                  e.description ?? 'Açıklama yok',
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
                                  Text("Lokasyon: ${e.workLocation!}"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 30),
              // --- Son Eklenen Malzemeler ---
              Text(
                'Son Eklenen Malzemeler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: 130,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .doc(customer.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Bir hata oluştu, lütfen tekrar deneyin.'),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!.data();
                    final List materialsJson = data?['materials'] ?? [];
                    final List<CustomerMaterial> mats = materialsJson
                        .map(
                          (e) => CustomerMaterial.fromJson(
                            Map<String, dynamic>.from(e as Map),
                          ),
                        )
                        .toList();

                    if (mats.isEmpty) {
                      return const Center(child: Text('Malzeme yok.'));
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mats.length,
                      itemBuilder: (context, idx) {
                        final m = mats[idx];
                        final tutar = (m.price ?? 0) * (m.quantity);
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Miktar: ${m.quantity} ${m.unit}"),
                                if (m.price != null)
                                  Text(
                                    "Fiyat: ${m.price!.toStringAsFixed(2)} ₺",
                                  ),
                                if (tutar > 0)
                                  Text("Tutar: ${tutar.toStringAsFixed(2)} ₺"),
                                if (m.note != null && m.note!.isNotEmpty)
                                  Text('Not: ${m.note!}'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 30),

              // --- Tablo Kalemleri ---
              Text(
                'Tablo Kalemleri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: 130,
                child: StreamBuilder<List<OtherWorkEntry>>(
                  stream: _otherEntriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Bir hata oluştu, lütfen tekrar deneyin.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final entries = snapshot.data!;
                    if (entries.isEmpty) {
                      return const Center(child: Text('Tablo kalemi yok.'));
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
                                  e.description ?? 'Açıklama yok',
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
                                  Text("Lokasyon: ${e.workLocation!}"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 30),
              // --- Görevler ---
              Text('Görevler', style: Theme.of(context).textTheme.titleLarge),
              if (customerTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Bu müşteri için görev yok.')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customerTasks.length,
                  itemBuilder: (context, i) {
                    final task = customerTasks[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          task.status == TaskStatus.done
                              ? Icons.check_circle
                              : task.status == TaskStatus.inProgress
                              ? Icons.timelapse
                              : Icons.radio_button_unchecked,
                          color: task.status == TaskStatus.done
                              ? Colors.green
                              : null,
                        ),
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Text(
                          "${task.date.day}.${task.date.month}.${task.date.year}",
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
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
        tooltip: 'Bu müşteri için görev ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Kısa örnek bir görev ekleme sayfası
class TaskForm extends StatelessWidget {
  final String? initialCustomerId;
  const TaskForm({super.key, this.initialCustomerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görev Ekle')),
      body: Center(child: Text('Seçili müşteri: ${initialCustomerId ?? "-"}')),
    );
  }
}
