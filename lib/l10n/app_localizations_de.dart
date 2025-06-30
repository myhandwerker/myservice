// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get customerDetailTitle => 'Kundendetails';

  @override
  String get invalidCustomerMessage => 'Ungültiger Kunde! Bitte zuerst einen Kunden anlegen.';

  @override
  String customerId(Object id) {
    return 'Kunden-ID: $id';
  }

  @override
  String get detail => 'Detail';

  @override
  String get workEntry => 'Arbeitseintrag';

  @override
  String get material => 'Material';

  @override
  String get materials => 'Materialien';

  @override
  String get contactAndOtherInfo => 'Kontakt- und weitere Informationen';

  @override
  String phone(Object phone) {
    return 'Telefon: $phone';
  }

  @override
  String email(Object email) {
    return 'E-Mail: $email';
  }

  @override
  String address(Object address) {
    return 'Adresse: $address';
  }

  @override
  String note(Object note) {
    return 'Notiz: $note';
  }

  @override
  String get latestHourlyWorkEntries => 'Neueste Stundeneinträge';

  @override
  String get noHourlyWorkEntry => 'Kein Stundeneintrag.';

  @override
  String get noDescription => 'Keine Beschreibung';

  @override
  String date(Object date) {
    return 'Datum: $date';
  }

  @override
  String amount(Object amount) {
    return 'Betrag: $amount';
  }

  @override
  String location(Object location) {
    return 'Ort: $location';
  }

  @override
  String get latestMaterials => 'Zuletzt hinzugefügte Materialien';

  @override
  String get noMaterial => 'Kein Material.';

  @override
  String quantity(Object quantity) {
    return 'Menge: $quantity';
  }

  @override
  String price(Object price) {
    return 'Preis: $price';
  }

  @override
  String get latestTableEntries => 'Neueste Tabellenposten';

  @override
  String get noTableEntry => 'Kein Tabellenposten.';

  @override
  String get tasks => 'Aufgaben';

  @override
  String get noTaskForCustomer => 'Keine Aufgabe für diesen Kunden.';

  @override
  String get addTaskForCustomer => 'Aufgabe für diesen Kunden hinzufügen';

  @override
  String get addTask => 'Aufgabe hinzufügen';

  @override
  String selectedCustomer(Object customerId) {
    return 'Ausgewählter Kunde: $customerId';
  }

  @override
  String get loadError => 'Ein Fehler ist aufgetreten, bitte versuchen Sie es erneut.';
}
