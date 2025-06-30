// lib/modules/invoices/invoice_item_model.dart

import 'package:flutter/material.dart';

enum InvoiceItemType {
  material('Malzeme'),
  workHour('İşçilik'),
  kilometerCost('Seyahat'),
  other('Diğer');

  final String displayName;
  const InvoiceItemType(this.displayName);

  static InvoiceItemType fromString(String type) {
    return InvoiceItemType.values.firstWhere(
      (e) => e.displayName == type,
      orElse: () => InvoiceItemType.other,
    );
  }
}

class InvoiceItem {
  final String description;
  final InvoiceItemType type;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      // description'ı String'e dönüştür
      description: map['description']?.toString() ?? '',
      // type'ı String'e dönüştürerek fromString metoduna gönder
      type: InvoiceItemType.fromString(map['type']?.toString() ?? 'Diğer'),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      // unit'i String'e dönüştür
      unit: map['unit']?.toString() ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'type': type.displayName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}
