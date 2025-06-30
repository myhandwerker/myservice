import 'package:flutter/material.dart';

enum WorkEntryType { hourly, road, accommodation, meter, lumpSum, other }

class WorkBreak {
  final TimeOfDay start;
  final TimeOfDay end;

  WorkBreak({required this.start, required this.end});

  int get breakMinutes =>
      (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);

  Map<String, dynamic> toJson() => {
        'startHour': start.hour,
        'startMinute': start.minute,
        'endHour': end.hour,
        'endMinute': end.minute,
      };

  factory WorkBreak.fromJson(Map<String, dynamic> json) => WorkBreak(
        start: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
        end: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      );
}

class WorkEntry {
  final String id;
  final WorkEntryType type;
  final DateTime date;

  // Saatlik işçilik için:
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<WorkBreak>? breaks;
  final double? hourlyRate;
  final String? workLocation;

  // Ortak alanlar:
  final double? amount;
  final double? unitPrice;
  final double? totalCost; // Düzeltme: total -> totalCost (tüm modelde aynı isim kullanılacak)
  final String? description;

  // Yol için:
  final double? distance;
  final double? distanceRate;

  // Firestore doküman ID'si
  final String? docId;

  WorkEntry({
    required this.id,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.breaks,
    this.hourlyRate,
    this.workLocation,
    this.amount,
    this.unitPrice,
    this.totalCost,
    this.description,
    this.distance,
    this.distanceRate,
    this.docId,
  });

  double? get netHours {
    if (type != WorkEntryType.hourly || startTime == null || endTime == null) return null;
    final start = startTime!.hour * 60 + startTime!.minute;
    final end = endTime!.hour * 60 + endTime!.minute;
    int diff = end >= start ? end - start : (24 * 60 - start) + end;
    int totalBreak = (breaks ?? []).fold(0, (sum, b) => sum + b.breakMinutes);
    return (diff - totalBreak) / 60.0;
  }

  double? get workCost {
    if (type == WorkEntryType.hourly) {
      return (netHours ?? 0) * (hourlyRate ?? 0);
    }
    return (amount ?? 0) * (unitPrice ?? 0);
  }

  double? get travelCost {
    if (type == WorkEntryType.hourly && distance != null && distanceRate != null) {
      return distance! * distanceRate!;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'date': date.toIso8601String(),
        // Saatlik alanlar:
        'startTimeHour': startTime?.hour,
        'startTimeMinute': startTime?.minute,
        'endTimeHour': endTime?.hour,
        'endTimeMinute': endTime?.minute,
        'breaks': breaks?.map((b) => b.toJson()).toList(),
        'hourlyRate': hourlyRate,
        'workLocation': workLocation,
        // Ortak:
        'amount': amount,
        'unitPrice': unitPrice,
        'totalCost': totalCost, // Düzeltme: total -> totalCost
        'description': description,
        // Yol:
        'distance': distance,
        'distanceRate': distanceRate,
        // docId Firestore'da tutulmaz, localde iş için kullanılabilir
      };

  factory WorkEntry.fromJson(Map<String, dynamic> json, {String? docId}) => WorkEntry(
        id: json['id'],
        type: WorkEntryType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => WorkEntryType.hourly,
        ),
        date: DateTime.parse(json['date']),
        // Saatlik:
        startTime: (json['startTimeHour'] != null && json['startTimeMinute'] != null)
            ? TimeOfDay(hour: json['startTimeHour'], minute: json['startTimeMinute'])
            : null,
        endTime: (json['endTimeHour'] != null && json['endTimeMinute'] != null)
            ? TimeOfDay(hour: json['endTimeHour'], minute: json['endTimeMinute'])
            : null,
        breaks: (json['breaks'] as List<dynamic>?)
            ?.map((b) => WorkBreak.fromJson(Map<String, dynamic>.from(b)))
            .toList(),
        hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
        workLocation: json['workLocation'],
        // Ortak:
        amount: (json['amount'] as num?)?.toDouble(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        totalCost: (json['totalCost'] as num?)?.toDouble(), // Düzeltme: total -> totalCost
        description: json['description'],
        // Yol:
        distance: (json['distance'] as num?)?.toDouble(),
        distanceRate: (json['distanceRate'] as num?)?.toDouble(),
        docId: docId, // Firestore doküman ID'si
      );

  // Firestore'dan listelerken doküman id ile birlikte kullan:
  static WorkEntry fromFirestoreDoc(Map<String, dynamic> data, String docId) =>
      WorkEntry.fromJson(data, docId: docId);
}