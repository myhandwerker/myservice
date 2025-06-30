// lib/models/proposal.dart
import 'package:flutter/material.dart'; // Renkler ve ikonlar için (isteğe bağlı)
import 'package:uuid/uuid.dart'; // ID oluşturmak için

// ProposalStatus enum'ı, teklifin durumunu belirtir.
enum ProposalStatus {
  pending, // Beklemede
  accepted, // Kabul Edildi
  rejected, // Reddedildi
}

// ProposalStatusExtension, ProposalStatus enum'ına ek özellikler ekler.
extension ProposalStatusExtension on ProposalStatus {
  Color get displayColor {
    switch (this) {
      case ProposalStatus.pending:
        return Colors.orange; // Beklemede için turuncu
      case ProposalStatus.accepted:
        return Colors.green; // Kabul edildi için yeşil
      case ProposalStatus.rejected:
        return Colors.red; // Reddedildi için kırmızı
    }
  }

  String get displayName {
    switch (this) {
      case ProposalStatus.pending:
        return 'Beklemede';
      case ProposalStatus.accepted:
        return 'Kabul Edildi';
      case ProposalStatus.rejected:
        return 'Reddedildi';
    }
  }
}

class Proposal {
  final String id;
  String title; // Başlık artık final değil
  String customerName; // customer yerine customerName
  double amount; // Tutar artık final değil
  ProposalStatus status; // Durum artık ProposalStatus enum
  DateTime date; // Tarih artık final değil
  String description; // Açıklama artık final değil
  String request; // Müşteri isteği artık final değil

  Proposal({
    String? id, // Opsiyonel ID, yoksa yeni oluşturulur
    required this.title,
    required this.customerName, // Müşteri adı
    required this.amount,
    this.status = ProposalStatus.pending, // Varsayılan durum
    required this.date,
    required this.description,
    required this.request,
  }) : id = id ?? const Uuid().v4(); // ID sağlanmazsa yeni bir UUID oluşturur

  // copyWith metodu, Proposal nesnesini kolayca kopyalamak ve değiştirmek için
  Proposal copyWith({
    String? id,
    String? title,
    String? customerName,
    double? amount,
    ProposalStatus? status,
    DateTime? date,
    String? description,
    String? request,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      date: date ?? this.date,
      description: description ?? this.description,
      request: request ?? this.request,
    );
  }

  // JSON'dan Proposal nesnesi oluşturmak için factory metodu
  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] as String,
      title: json['title'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: ProposalStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ProposalStatus.pending, // Varsayılan değer
      ),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      request: json['request'] as String,
    );
  }

  // Proposal nesnesini JSON'a dönüştürmek için metot
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'customerName': customerName,
      'amount': amount,
      'status': status.toString(), // Enum'ı string olarak kaydet
      'date': date.toIso8601String(), // Tarihi ISO formatında kaydet
      'description': description,
      'request': request,
    };
  }
}
