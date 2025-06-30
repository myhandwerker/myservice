enum OtherWorkEntryUnit { goturu, metre, metrekare }

class OtherWorkEntry {
  final String id;
  final DateTime date;
  final String? description;
  final double? amount;
  final OtherWorkEntryUnit unit;
  final double? unitPrice;
  final double? workCost;
  final String? workLocation;
  final double? distance;
  final double? distanceRate;
  final double? travelCost;
  final int? accommodationNights;
  final double? accommodationPrice;
  final double? accommodationCost;
  final double? totalCost;
  final String type;
  final String? docId; // Firestore doküman ID'si için (opsiyonel)

  OtherWorkEntry({
    required this.id,
    required this.date,
    this.description,
    this.amount,
    required this.unit,
    this.unitPrice,
    this.workCost,
    this.workLocation,
    this.distance,
    this.distanceRate,
    this.travelCost,
    this.accommodationNights,
    this.accommodationPrice,
    this.accommodationCost,
    this.totalCost,
    this.type = "OtherWorkEntry",
    this.docId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'unit': unit.toString(),
    'unitPrice': unitPrice,
    'workCost': workCost,
    'workLocation': workLocation,
    'distance': distance,
    'distanceRate': distanceRate,
    'travelCost': travelCost,
    'accommodationNights': accommodationNights,
    'accommodationPrice': accommodationPrice,
    'accommodationCost': accommodationCost,
    'totalCost': totalCost,
    'type': type,
    // docId Firestore'da tutulmaz, localde iş için kullanılabilir
  };

  factory OtherWorkEntry.fromJson(Map<String, dynamic> json, {String? docId}) =>
      OtherWorkEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        description: json['description'],
        amount: (json['amount'] as num?)?.toDouble(),
        unit: OtherWorkEntryUnit.values.firstWhere(
          (e) => e.toString() == json['unit'],
          orElse: () => OtherWorkEntryUnit.goturu,
        ),
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        workCost: (json['workCost'] as num?)?.toDouble(),
        workLocation: json['workLocation'],
        distance: (json['distance'] as num?)?.toDouble(),
        distanceRate: (json['distanceRate'] as num?)?.toDouble(),
        travelCost: (json['travelCost'] as num?)?.toDouble(),
        accommodationNights: (json['accommodationNights'] as num?)?.toInt(),
        accommodationPrice: (json['accommodationPrice'] as num?)?.toDouble(),
        accommodationCost: (json['accommodationCost'] as num?)?.toDouble(),
        totalCost: (json['totalCost'] as num?)?.toDouble(),
        type: json['type'] ?? "OtherWorkEntry",
        docId: docId,
      );

  // Firestore'dan okurken doküman id'si ile birlikte kullanmak için:
  static OtherWorkEntry fromFirestoreDoc(
    Map<String, dynamic> data,
    String docId,
  ) => OtherWorkEntry.fromJson(data, docId: docId);
}
