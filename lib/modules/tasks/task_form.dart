import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../customers/customer_model.dart';
import '../customers/customer_form.dart';
import '../customers/customer_material_form.dart'; // Malzeme için
import '../customers/work_entry_screen.dart'; // İşçilik için
import 'task_model.dart';
import 'task_helpers.dart';

class TaskForm extends StatefulWidget {
  final Task? initialTask;
  final String? initialCustomerId;
  final DateTime? initialDate;

  const TaskForm({
    super.key,
    this.initialTask,
    this.initialCustomerId,
    this.initialDate,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  DateTime? date;
  String? selectedCustomerId;
  TaskStatus? selectedStatus;
  Customer? selectedCustomer;
  List<Customer> allCustomers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    titleController = TextEditingController(text: task?.title ?? "");
    descriptionController = TextEditingController(
      text: task?.description ?? "",
    );
    date = task?.date ?? widget.initialDate ?? DateTime.now();
    selectedCustomerId = task?.customerId ?? widget.initialCustomerId;
    selectedStatus = task?.status ?? TaskStatus.todo;
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final query = await FirebaseFirestore.instance
        .collection('customers')
        .get();
    setState(() {
      allCustomers = query.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return Customer.fromMap(map);
      }).toList();
      if (selectedCustomerId != null && allCustomers.isNotEmpty) {
        selectedCustomer = allCustomers.firstWhere(
          (c) => c.id == selectedCustomerId,
          orElse: () => allCustomers.first,
        );
      } else {
        selectedCustomer = null;
      }
    });
  }

  Future<void> _showAddCustomerForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.95,
          child: CustomerFormScreen(),
        ),
      ),
    );
    if (result != null) {
      await _fetchCustomers();
      if (allCustomers.isNotEmpty) {
        final latestCustomer = allCustomers.last;
        setState(() {
          selectedCustomerId = latestCustomer.id;
          selectedCustomer = latestCustomer;
        });
      }
    }
  }

  Future<void> _saveTaskToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final docId =
          widget.initialTask?.id ??
          FirebaseFirestore.instance.collection('tasks').doc().id;
      final taskData = Task(
        id: docId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        date: date!,
        status: selectedStatus!,
        customerId: selectedCustomerId,
      ).toMap();
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(docId)
          .set(taskData);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final colorScheme = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lütfen işlemin bitmesini bekleyin.")),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEditing ? "Görev Düzenle" : "Yeni Görev")),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Başlık"),
                    validator: (val) =>
                        (val?.trim().isEmpty ?? true) ? "Başlık zorunlu" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                    minLines: 2,
                    maxLines: 4,
                    validator: (val) => (val?.trim().isEmpty ?? true)
                        ? "Açıklama zorunlu"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Autocomplete<Customer>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (allCustomers.isEmpty)
                              return const Iterable<Customer>.empty();
                            if (textEditingValue.text == '')
                              return allCustomers;
                            return allCustomers.where(
                              (Customer c) => c.name.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          displayStringForOption: (Customer option) =>
                              option.name,
                          initialValue: selectedCustomer != null
                              ? TextEditingValue(text: selectedCustomer!.name)
                              : const TextEditingValue(),
                          onSelected: (Customer selection) {
                            setState(() {
                              selectedCustomer = selection;
                              selectedCustomerId = selection.id;
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: "Müşteri (arama yapabilirsin)",
                                  ),
                                  validator: (val) => selectedCustomerId == null
                                      ? "Müşteri seçimi zorunlu"
                                      : null,
                                );
                              },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1),
                        tooltip: "Yeni müşteri ekle",
                        onPressed: _showAddCustomerForm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // MALZEME EKLE BUTONU
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text("Malzeme Ekle (Müşteriye)"),
                      onPressed: selectedCustomerId == null
                          ? null
                          : () async {
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => CustomerMaterialForm(
                                  customerId: selectedCustomerId!,
                                  onMaterialAdded: () {
                                    // İstersen görev formunda liste güncellemesi yapabilirsin
                                  },
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // İŞÇİLİK EKLE BUTONU
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.handyman_outlined),
                      label: const Text("İşçilik Ekle (Müşteriye)"),
                      onPressed: selectedCustomer == null
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkEntryScreen(
                                    customer: selectedCustomer!,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<TaskStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "Durum"),
                    items: const [
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
                    onChanged: (v) => setState(() => selectedStatus = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(
                      "Tarih: ${date != null ? "${date!.day}.${date!.month}.${date!.year}" : "Seçilmedi"}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isEditing ? "Kaydet" : "Ekle"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isLoading ? null : _saveTaskToFirestore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
