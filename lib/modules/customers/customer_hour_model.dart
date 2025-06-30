// myservice/lib/modules/customers/customer_hour_model.dart

class CustomerHour {
  DateTime date;
  String hours; // Çalışılan saatler, örneğin "8 saat" veya "Yarım gün"

  CustomerHour({required this.date, required this.hours});

  // CustomerHour nesnesini Map'e dönüştürme (Firestore'a yazmak için)
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(), // DateTime'ı ISO 8601 string olarak kaydet
      'hours': hours,
    };
  }

  // Map'ten CustomerHour nesnesi oluşturma (Firestore'dan okumak için)
  factory CustomerHour.fromMap(Map<String, dynamic> map) {
    return CustomerHour(
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      hours: map['hours'] ?? '',
    );
  }
}