// lib/modules/invoices/invoice_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_item_model.dart'; // InvoiceItem modelini import et
import 'package:flutter/material.dart'; // Color için

enum InvoiceStatus {
  pending('Beklemede', Colors.orange),
  paid('Ödendi', Colors.green),
  overdue('Gecikmiş', Colors.red),
  cancelled('İptal Edildi', Colors.grey);

  final String displayName;
  final Color displayColor;

  const InvoiceStatus(this.displayName, this.displayColor);

  static InvoiceStatus fromString(String status) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.displayName == status,
      orElse: () => InvoiceStatus.pending,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final String paymentTerms;
  final String? description;
  final double subtotal;
  final double discount;
  final double taxRate;
  final double totalTax;
  final double totalAmount;
  final List<InvoiceItem> items; // Fatura kalemleri listesi

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    this.dueDate,
    required this.status,
    required this.paymentTerms,
    this.description,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.totalTax,
    required this.totalAmount,
    required this.items,
  });

  // Firestore'dan Invoice nesnesi oluşturmak için factory metodu
  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // issueDate ve dueDate'i güvenli bir şekilde DateTime'a dönüştürme
    // Hem Timestamp hem de String formatlarını destekler
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      } else if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print("Tarih string'i parse edilirken hata oluştu: $value, Hata: $e");
          return null; // Parse hatasında null dön
        }
      }
      return null; // Beklenmedik türde ise null dön
    }

    return Invoice(
      id: doc.id,
      // invoiceNumber'ı her zaman String'e dönüştür
      invoiceNumber: data['invoiceNumber']?.toString() ?? '',
      issueDate: parseDate(data['issueDate']) ??
          DateTime.now(), // String veya Timestamp'ten DateTime'a çevir
      dueDate: parseDate(data[
          'dueDate']), // String veya Timestamp'ten DateTime'a çevir (null olabilir)
      // status'ü de String'e dönüştür
      status:
          InvoiceStatus.fromString(data['status']?.toString() ?? 'Beklemede'),
      // paymentTerms'ı da String'e dönüştür
      paymentTerms: data['paymentTerms']?.toString() ?? '',
      description: data['description'],
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      totalTax: (data['totalTax'] as num?)?.toDouble() ??
          0.0, // Düzeltme: totalTax da taxRate gibi hesaplanmalıydı. (Daha önce yaptığınız düzeltme)
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String,
                  dynamic>)) // Hatanın bu çağrı içinde olması bekleniyor
              .toList() ??
          [],
    );
  }

  // Invoice nesnesini Firestore'a kaydetmek için Map'e dönüştürme metodu
  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status.displayName,
      'paymentTerms': paymentTerms,
      'description': description,
      'subtotal': subtotal,
      'discount': discount,
      'taxRate': taxRate,
      'totalTax': totalTax, // totalTax'ı doğrudan kullanıyoruz
      'totalAmount': totalAmount,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
