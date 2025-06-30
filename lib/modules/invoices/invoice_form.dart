// lib/modules/invoices/invoice_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../utils/constants.dart';
import '../customers/customer_model.dart';
import '../settings/company_settings_model.dart';
import 'invoice_model.dart';
import 'invoice_item_model.dart';
import 'invoice_service.dart';

class InvoiceFormPage extends StatefulWidget {
  final Invoice? invoice;
  final Customer? initialCustomer;
  final CompanySettings companySettings;
  final List<Customer> allCustomers;

  const InvoiceFormPage({
    super.key,
    this.invoice,
    this.initialCustomer,
    required this.companySettings,
    required this.allCustomers,
  });

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _paymentTermsController;

  late DateTime _issueDate;
  DateTime? _dueDate;
  late InvoiceStatus _status;
  Customer? _selectedCustomer;
  late List<InvoiceItem> _items;

  double _subtotal = 0.0;
  double _discount = 0.0;
  double _taxRate = 0.0;
  double _totalTax = 0.0;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _taxRate = widget.companySettings.defaultTaxRate;

    if (widget.invoice != null) {
      _invoiceNumberController =
          TextEditingController(text: widget.invoice!.invoiceNumber);
      _descriptionController =
          TextEditingController(text: widget.invoice!.description);
      _paymentTermsController =
          TextEditingController(text: widget.invoice!.paymentTerms);
      _issueDate = widget.invoice!.issueDate;
      _dueDate = widget.invoice!.dueDate;
      _status = widget.invoice!.status;
      _selectedCustomer = widget.initialCustomer ??
          (widget.allCustomers.isNotEmpty
              ? widget.allCustomers.first
              : Customer.empty());
      _items = List.from(widget.invoice!.items);
      _discount = widget.invoice!.discount;
    } else {
      _invoiceNumberController = TextEditingController(
          text:
              '${widget.companySettings.invoiceNumberPrefix}${DateFormat('yyyyMMdd').format(DateTime.now())}-${_uuid.v4().substring(0, 4)}');
      _descriptionController = TextEditingController();
      _paymentTermsController = TextEditingController(
          text: widget.companySettings.defaultPaymentTerms);
      _issueDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));
      _status = InvoiceStatus.pending;
      _selectedCustomer = widget.initialCustomer ??
          (widget.allCustomers.isNotEmpty
              ? widget.allCustomers.first
              : Customer.empty());
      _items = [];
    }

    _calculateTotals();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _descriptionController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    _subtotal = _items.fold(0.0, (sum, item) => sum + item.total);
    _totalTax = (_subtotal - _discount) * (_taxRate / 100);
    _totalAmount = (_subtotal - _discount) + _totalTax;
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : (_dueDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isIssueDate ? _issueDate : _dueDate)) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(
        description: '',
        type: InvoiceItemType.material,
        quantity: 1.0,
        unit: 'Adet',
        unitPrice: 0.0,
        total: 0.0,
      ));
      _calculateTotals();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotals();
    });
  }

  void _updateItem(int index, InvoiceItem newItem) {
    setState(() {
      _items[index] = newItem;
      _calculateTotals();
    });
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null ||
          _selectedCustomer!.id == Customer.empty().id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen geçerli bir müşteri seçin."),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen en az bir fatura kalemi ekleyin."),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final Invoice finalInvoice = Invoice(
        id: widget.invoice?.id ?? _uuid.v4(), // Yeni fatura için ID ataması
        invoiceNumber: _invoiceNumberController.text,
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: _status,
        paymentTerms: _paymentTermsController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        subtotal: _subtotal,
        discount: _discount,
        taxRate: _taxRate,
        totalTax: _totalTax,
        totalAmount: _totalAmount,
        items: _items,
      );

      try {
        if (widget.invoice == null) {
          await InvoiceService.addInvoice(finalInvoice);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Fatura başarıyla eklendi!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          await InvoiceService.updateInvoice(finalInvoice.id, finalInvoice);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Fatura başarıyla güncellendi!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
        if (context.mounted) {
          Navigator.pop(context, finalInvoice);
        }
      } catch (e) {
        print("Fatura kaydedilirken hata oluştu: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Fatura kaydedilirken hata oluştu: ${e.toString()}"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.invoice == null ? "Yeni Fatura Oluştur" : "Fatura Düzenle",
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.yellowAccent,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.padding),
          children: [
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'Fatura Numarası',
              ),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fatura numarası boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.padding),

            DropdownButtonFormField<Customer>(
              decoration: const InputDecoration(
                labelText: 'Müşteri',
              ),
              value: _selectedCustomer,
              items: widget.allCustomers.map((customer) {
                return DropdownMenuItem(
                  value: customer,
                  child: Text(
                    customer.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (Customer? newValue) {
                setState(() {
                  _selectedCustomer = newValue;
                });
              },
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              validator: (value) {
                if (value == null || value.id == Customer.empty().id) {
                  return 'Lütfen bir müşteri seçin';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.padding),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fatura Tarihi',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_issueDate),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.padding),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Vade Tarihi',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dueDate == null
                            ? 'Seçiniz'
                            : DateFormat('dd.MM.yyyy').format(_dueDate!),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padding),

            DropdownButtonFormField<InvoiceStatus>(
              decoration: const InputDecoration(
                labelText: 'Durum',
              ),
              value: _status,
              items: InvoiceStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.displayName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (InvoiceStatus? newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.padding),

            TextFormField(
              controller: _paymentTermsController,
              decoration: const InputDecoration(
                labelText: 'Ödeme Koşulları',
              ),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.padding),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe Bağlı)',
              ),
              maxLines: 3,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.padding * 1.5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fatura Kalemleri',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.yellowAccent),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, color: AppColors.background),
                  label: Text(
                    'Kalem Ekle',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.background),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padding),

            if (_items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppConstants.padding),
                child: Center(
                  child: Text(
                    'Henüz fatura kalemi eklenmedi.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.symmetric(
                        vertical: AppConstants.padding / 2),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Kalem ${index + 1}',
                                  style: AppTextStyles.titleSmall
                                      .copyWith(color: AppColors.yellowAccent),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.error),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                          TextFormField(
                            initialValue: item.description,
                            decoration:
                                const InputDecoration(labelText: 'Açıklama'),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                            onChanged: (value) {
                              _updateItem(
                                  index, item.copyWith(description: value));
                            },
                          ),
                          DropdownButtonFormField<InvoiceItemType>(
                            decoration: const InputDecoration(labelText: 'Tip'),
                            value: item.type,
                            items: InvoiceItemType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                _updateItem(
                                    index, item.copyWith(type: newValue));
                              }
                            },
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Miktar'),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textPrimary),
                                  onChanged: (value) {
                                    final newQuantity =
                                        double.tryParse(value) ?? 0.0;
                                    _updateItem(
                                        index,
                                        item.copyWith(
                                            quantity: newQuantity,
                                            total:
                                                newQuantity * item.unitPrice));
                                  },
                                ),
                              ),
                              const SizedBox(width: AppConstants.padding),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.unit,
                                  decoration:
                                      const InputDecoration(labelText: 'Birim'),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textPrimary),
                                  onChanged: (value) {
                                    _updateItem(
                                        index, item.copyWith(unit: value));
                                  },
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            initialValue: item.unitPrice.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Birim Fiyat'),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                            onChanged: (value) {
                              final newUnitPrice =
                                  double.tryParse(value) ?? 0.0;
                              _updateItem(
                                  index,
                                  item.copyWith(
                                      unitPrice: newUnitPrice,
                                      total: newUnitPrice * item.quantity));
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Toplam: ${item.total.toStringAsFixed(2)} ${widget.companySettings.defaultCurrency}',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.yellowAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppConstants.padding * 1.5),

            // Toplamlar
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Ara Toplam: ${_subtotal.toStringAsFixed(2)} ${widget.companySettings.defaultCurrency}",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    TextFormField(
                      initialValue: _discount.toStringAsFixed(2),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'İndirim (${widget.companySettings.defaultCurrency})',
                        suffixText: widget.companySettings.defaultCurrency,
                      ),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                      onChanged: (value) {
                        setState(() {
                          _discount = double.tryParse(value) ?? 0.0;
                          _calculateTotals();
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.padding / 2),
                    Text(
                      "Vergi Oranı: %${_taxRate.toStringAsFixed(2)}",
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      "Toplam Vergi: ${_totalTax.toStringAsFixed(2)} ${widget.companySettings.defaultCurrency}",
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const Divider(color: AppColors.divider),
                    Text(
                      "Genel Toplam: ${_totalAmount.toStringAsFixed(2)} ${widget.companySettings.defaultCurrency}",
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.yellowAccent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padding),

            // Kaydet Düğmesi
            ElevatedButton(
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: AppConstants.padding),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Text(
                widget.invoice == null
                    ? 'Faturayı Oluştur'
                    : 'Faturayı Güncelle',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension InvoiceItemCopyWith on InvoiceItem {
  InvoiceItem copyWith({
    String? description,
    InvoiceItemType? type,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}
