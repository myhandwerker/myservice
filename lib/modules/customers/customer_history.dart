import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myservice/modules/customers/customer_model.dart';
import 'package:myservice/modules/tasks/task_model.dart';

class CustomerHistoryPage extends StatefulWidget {
  final Customer customer;

  const CustomerHistoryPage({super.key, required this.customer});

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Firestore stream with customer id check
  Stream<QuerySnapshot<Map<String, dynamic>>> _taskStream() {
    if (widget.customer.id.isEmpty) {
      // Return empty stream if customer id is invalid
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('customerId', isEqualTo: widget.customer.id)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _invoiceStream() {
    if (widget.customer.id.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('invoices')
        .where('customerId', isEqualTo: widget.customer.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent Firestore access if id is empty
    if (widget.customer.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geçmiş')),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Geçmiş'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Görevler', icon: Icon(Icons.task)),
            Tab(text: 'Faturalar', icon: Icon(Icons.receipt)),
            Tab(text: 'Malzemeler', icon: Icon(Icons.inventory)),
            Tab(text: 'İşçilik', icon: Icon(Icons.handyman)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // Görevler Tabı
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _taskStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Henüz görev yok.'));
              }
              final tasks = snapshot.data!.docs
                  .map((doc) => Task.fromMap(doc.data()))
                  .toList();
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  return ListTile(
                    title: Text(task.title ?? ''),
                    subtitle: Text(task.description ?? ''),
                    trailing: Text(
                      task.status.name,
                      style: TextStyle(
                        color: task.status == TaskStatus.done
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Faturalar Tabı
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _invoiceStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Henüz fatura yok.'));
              }
              final invoices = snapshot.data!.docs;
              return ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (context, i) {
                  final invoice = invoices[i].data();
                  return ListTile(
                    title: Text(
                      'Fatura #: ${invoice['invoiceNumber']?.toString() ?? ''}',
                    ),
                    subtitle: Text(
                      'Tutar: ${invoice['amount']?.toString() ?? ''} ₺',
                    ),
                    trailing: Text(
                      invoice['date']?.toString() ?? '',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  );
                },
              );
            },
          ),
          // Malzemeler Tabı
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _taskStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Henüz malzeme yok.'));
              }
              // Tüm görevlerden malzemeleri topla
              final allMaterials = snapshot.data!.docs
                  .map((doc) => Task.fromMap(doc.data()))
                  .expand((task) => task.materials)
                  .toList();
              if (allMaterials.isEmpty) {
                return const Center(child: Text('Henüz malzeme yok.'));
              }
              return ListView.builder(
                itemCount: allMaterials.length,
                itemBuilder: (context, i) {
                  final material = allMaterials[i];
                  return ListTile(
                    title: Text(material.name ?? ''),
                    subtitle: Text(
                      'Miktar: ${material.quantity?.toString() ?? ''}',
                    ),
                  );
                },
              );
            },
          ),
          // İşçilik Tabı
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _taskStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Henüz işçilik yok.'));
              }
              // Tüm görevlerden işçilikleri topla
              final allLabors = snapshot.data!.docs
                  .map((doc) => Task.fromMap(doc.data()))
                  .expand((task) => task.labors)
                  .toList();
              if (allLabors.isEmpty) {
                return const Center(child: Text('Henüz işçilik yok.'));
              }
              return ListView.builder(
                itemCount: allLabors.length,
                itemBuilder: (context, i) {
                  final labor = allLabors[i];
                  return ListTile(
                    title: Text(labor.description ?? ''),
                    subtitle: Text(
                      'Süre: ${labor.duration?.toString() ?? ''} saat',
                    ),
                    trailing: Text(labor.worker ?? ''),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
