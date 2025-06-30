import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @customerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Detail'**
  String get customerDetailTitle;

  /// No description provided for @invalidCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid customer! Please create a customer first.'**
  String get invalidCustomerMessage;

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer ID: {id}'**
  String customerId(Object id);

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @workEntry.
  ///
  /// In en, this message translates to:
  /// **'Labor / Work'**
  String get workEntry;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// No description provided for @contactAndOtherInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact and Other Information'**
  String get contactAndOtherInfo;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String phone(Object phone);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String email(Object email);

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String address(Object address);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String note(Object note);

  /// No description provided for @latestHourlyWorkEntries.
  ///
  /// In en, this message translates to:
  /// **'Latest Hourly Work Entries'**
  String get latestHourlyWorkEntries;

  /// No description provided for @noHourlyWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'No hourly work entry.'**
  String get noHourlyWorkEntry;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String date(Object date);

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String amount(Object amount);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String location(Object location);

  /// No description provided for @latestMaterials.
  ///
  /// In en, this message translates to:
  /// **'Latest Added Materials'**
  String get latestMaterials;

  /// No description provided for @noMaterial.
  ///
  /// In en, this message translates to:
  /// **'No material.'**
  String get noMaterial;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity}'**
  String quantity(Object quantity);

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price: {price}'**
  String price(Object price);

  /// No description provided for @latestTableEntries.
  ///
  /// In en, this message translates to:
  /// **'Latest Table Items'**
  String get latestTableEntries;

  /// No description provided for @noTableEntry.
  ///
  /// In en, this message translates to:
  /// **'No table item.'**
  String get noTableEntry;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @noTaskForCustomer.
  ///
  /// In en, this message translates to:
  /// **'No task for this customer.'**
  String get noTaskForCustomer;

  /// No description provided for @addTaskForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add task for this customer'**
  String get addTaskForCustomer;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @selectedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Selected customer: {customerId}'**
  String selectedCustomer(Object customerId);

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again.'**
  String get loadError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
