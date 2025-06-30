import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class PaymentTracking extends StatefulWidget {
  const PaymentTracking({super.key});

  @override
  State<PaymentTracking> createState() => _PaymentTrackingState();
}

class _PaymentTrackingState extends State<PaymentTracking> {
  final List<_Payment> payments = [];
  final _formKey = GlobalKey<FormState>();
  double? amount;
  DateTime? date;
  String? desc;

  void _addPayment() async {
    if (!_formKey.currentState!.validate()) return;
    final payment = _Payment(
      amount: amount!,
      date: date ?? DateTime.now(),
      description: desc ?? "",
    );

    setState(() {
      payments.add(payment);
      amount = null;
      date = null;
      desc = null;
    });
    _formKey.currentState!.reset();

    // Firestore'a kaydet
    await FirebaseFirestore.instance.collection('payments').add({
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'description': payment.description,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ödeme Takibi'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Tutar",
                        prefixIcon: Icon(Icons.payment),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null ||
                              double.tryParse(v) == null ||
                              double.tryParse(v)! <= 0)
                          ? "Geçerli tutar girin"
                          : null,
                      onChanged: (v) => amount = double.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Açıklama",
                        prefixIcon: Icon(Icons.description),
                      ),
                      onChanged: (v) => desc = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.success),
                    onPressed: _addPayment,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Text(
                        "Henüz ödeme yok.",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, i) {
                        final p = payments[i];
                        return Card(
                          color: AppColors.surface,
                          child: ListTile(
                            leading: Icon(
                              Icons.monetization_on,
                              color: AppColors.success,
                            ),
                            title: Text("${p.amount.toStringAsFixed(2)} ₺"),
                            subtitle: Text(
                              "${p.description} - ${p.date.day}.${p.date.month}.${p.date.year}",
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Payment {
  final double amount;
  final DateTime date;
  final String description;
  _Payment({
    required this.amount,
    required this.date,
    required this.description,
  });
}
