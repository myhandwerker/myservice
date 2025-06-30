// lib/modules/customers/customer_material_model.dart
import 'package:flutter/material.dart';

class CustomerMaterial {
  final String name;
  final double quantity;
  final String unit;
  final double? price;
  final String? note;

  CustomerMaterial({
    required this.name,
    required this.quantity,
    required this.unit,
    this.price,
    this.note,
  });

  factory CustomerMaterial.fromJson(Map<String, dynamic> json) {
    return CustomerMaterial(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'note': note,
    };
  }
}
