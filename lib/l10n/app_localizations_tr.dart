// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get customerDetailTitle => 'Müşteri Detay';

  @override
  String get invalidCustomerMessage => 'Geçersiz müşteri! Lütfen önce müşteri oluşturun.';

  @override
  String customerId(Object id) {
    return 'Müşteri ID: $id';
  }

  @override
  String get detail => 'Detay';

  @override
  String get workEntry => 'İşçilik / Çalışma';

  @override
  String get material => 'Malzeme';

  @override
  String get materials => 'Malzemeler';

  @override
  String get contactAndOtherInfo => 'İletişim ve Diğer Bilgiler';

  @override
  String phone(Object phone) {
    return 'Telefon: $phone';
  }

  @override
  String email(Object email) {
    return 'E-posta: $email';
  }

  @override
  String address(Object address) {
    return 'Adres: $address';
  }

  @override
  String note(Object note) {
    return 'Not: $note';
  }

  @override
  String get latestHourlyWorkEntries => 'Son Eklenen Saatlik İşçilikler';

  @override
  String get noHourlyWorkEntry => 'Saatlik işçilik yok.';

  @override
  String get noDescription => 'Açıklama yok';

  @override
  String date(Object date) {
    return 'Tarih: $date';
  }

  @override
  String amount(Object amount) {
    return 'Tutar: $amount';
  }

  @override
  String location(Object location) {
    return 'Yer: $location';
  }

  @override
  String get latestMaterials => 'Son Eklenen Malzemeler';

  @override
  String get noMaterial => 'Malzeme yok.';

  @override
  String quantity(Object quantity) {
    return 'Miktar: $quantity';
  }

  @override
  String price(Object price) {
    return 'Fiyat: $price';
  }

  @override
  String get latestTableEntries => 'Son Eklenen Tablo Kalemleri';

  @override
  String get noTableEntry => 'Tablo kalemi yok.';

  @override
  String get tasks => 'Görevler';

  @override
  String get noTaskForCustomer => 'Bu müşteriye ait görev yok.';

  @override
  String get addTaskForCustomer => 'Bu müşteriye görev ekle';

  @override
  String get addTask => 'Görev Ekle';

  @override
  String selectedCustomer(Object customerId) {
    return 'Seçili müşteri: $customerId';
  }

  @override
  String get loadError => 'An error occurred, please try again.';
}
