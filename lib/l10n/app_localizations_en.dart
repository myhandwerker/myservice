// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get customerDetailTitle => 'Customer Detail';

  @override
  String get invalidCustomerMessage => 'Invalid customer! Please create a customer first.';

  @override
  String customerId(Object id) {
    return 'Customer ID: $id';
  }

  @override
  String get detail => 'Detail';

  @override
  String get workEntry => 'Labor / Work';

  @override
  String get material => 'Material';

  @override
  String get materials => 'Materials';

  @override
  String get contactAndOtherInfo => 'Contact and Other Information';

  @override
  String phone(Object phone) {
    return 'Phone: $phone';
  }

  @override
  String email(Object email) {
    return 'Email: $email';
  }

  @override
  String address(Object address) {
    return 'Address: $address';
  }

  @override
  String note(Object note) {
    return 'Note: $note';
  }

  @override
  String get latestHourlyWorkEntries => 'Latest Hourly Work Entries';

  @override
  String get noHourlyWorkEntry => 'No hourly work entry.';

  @override
  String get noDescription => 'No description';

  @override
  String date(Object date) {
    return 'Date: $date';
  }

  @override
  String amount(Object amount) {
    return 'Amount: $amount';
  }

  @override
  String location(Object location) {
    return 'Location: $location';
  }

  @override
  String get latestMaterials => 'Latest Added Materials';

  @override
  String get noMaterial => 'No material.';

  @override
  String quantity(Object quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String price(Object price) {
    return 'Price: $price';
  }

  @override
  String get latestTableEntries => 'Latest Table Items';

  @override
  String get noTableEntry => 'No table item.';

  @override
  String get tasks => 'Tasks';

  @override
  String get noTaskForCustomer => 'No task for this customer.';

  @override
  String get addTaskForCustomer => 'Add task for this customer';

  @override
  String get addTask => 'Add Task';

  @override
  String selectedCustomer(Object customerId) {
    return 'Selected customer: $customerId';
  }

  @override
  String get loadError => 'An error occurred, please try again.';
}
