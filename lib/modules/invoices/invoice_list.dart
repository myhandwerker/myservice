// lib/modules/invoices/invoice_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../customers/customer_model.dart';
import '../settings/company_settings_model.dart';
import '../../utils/constants.dart';
import 'invoice_model.dart';
import 'invoice_item_model.dart';
import 'invoice_detail.dart';
import 'invoice_form.dart'; // <<< BU İSİM DOĞRU
import 'invoice_service.dart';

class InvoiceList extends StatefulWidget {
  final Customer customer;
  final CompanySettings companySettings;
  final List<Customer> allCustomers;

  const InvoiceList({
    super.key,
    required this.customer,
    required this.companySettings,
    required this.allCustomers,
  });

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Invoice>>(
        stream: InvoiceService.streamInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: AppColors.yellowAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Faturalar yükleniyor...',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Fatura yüklenirken hata oluştu: ${snapshot.error}',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Henüz Fatura Yok',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            );
          }

          final invoices = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.padding),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(
                    vertical: AppConstants.padding / 2),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppConstants.padding),
                  title: Text(
                    invoice.invoiceNumber,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.yellowAccent),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Müşteri: ${widget.customer.name}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        'Tarih: ${DateFormat('dd.MM.yyyy').format(invoice.issueDate)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        'Durum: ${invoice.status.displayName}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: invoice.status.displayColor),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} ${widget.companySettings.defaultCurrency}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.yellowAccent),
                  ),
                  onTap: () async {
                    final updatedInvoice = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceFormPage(
                          invoice: invoice,
                          companySettings: widget.companySettings,
                          allCustomers: widget.allCustomers,
                          initialCustomer: widget.customer,
                        ),
                      ),
                    );
                    if (context.mounted &&
                        updatedInvoice != null &&
                        updatedInvoice is Invoice) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fatura başarıyla güncellendi!"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newInvoice = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceFormPage(
                companySettings: widget.companySettings,
                allCustomers: widget.allCustomers,
                initialCustomer: widget.customer,
              ),
            ),
          );

          if (context.mounted && newInvoice != null && newInvoice is Invoice) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Yeni fatura başarıyla eklendi!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        backgroundColor: AppColors.yellowAccent,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }
}
