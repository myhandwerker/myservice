// lib/modules/settings/company_settings_model.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart'; // AppColors ve AppConstants için

class CompanySettings {
  final String companyName;
  final String? companyDescription;
  final String? logoPath;
  final Color? themeColor;

  // Fatura Ayarları
  final String companyAddress;
  final String contactPhone;
  final String contactFax;
  final String contactMobile;
  final String contactEmail;
  final String contactWebsite;
  final String invoiceHeader;
  final String invoiceNumberPrefix;
  final double defaultTaxRate;
  final String defaultCurrency;
  final String defaultPaymentTerms;
  final String invoiceFooter;

  // Footer Bilgileri
  final String footerCompanyName;
  final String footerAddress;
  final String footerPhone;
  final String footerFax;
  final String footerEmail;
  final String bankName;
  final String iban;
  final String taxNumber;
  final String financeOffice;

  // PDF Özelleştirme Ayarları
  final String? pdfFontFamily; // PDF yazı tipi ailesi eklendi
  final int? pdfTextColor; // PDF yazı tipi rengi eklendi (ARGB int değeri)

  CompanySettings({
    required this.companyName,
    this.companyDescription,
    this.logoPath,
    this.themeColor,
    required this.companyAddress,
    required this.contactPhone,
    required this.contactFax,
    required this.contactMobile,
    required this.contactEmail,
    required this.contactWebsite,
    required this.invoiceHeader,
    required this.invoiceNumberPrefix,
    required this.defaultTaxRate,
    required this.defaultCurrency,
    required this.defaultPaymentTerms,
    required this.invoiceFooter,
    required this.footerCompanyName,
    required this.footerAddress,
    required this.footerPhone,
    required this.footerFax,
    required this.footerEmail,
    required this.bankName,
    required this.iban,
    required this.taxNumber,
    required this.financeOffice,
    this.pdfFontFamily, // Yapılandırıcıya eklendi
    this.pdfTextColor, // Yapılandırıcıya eklendi
  });

  // JSON'dan veya Map'ten CompanySettings nesnesi oluşturur
  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      companyName: json['companyName'] ?? 'Şirket Adı',
      companyDescription: json['companyDescription'],
      logoPath: json['logoPath'],
      themeColor: json['themeColor'] != null
          ? Color(json['themeColor'] as int)
          : AppColors.yellowAccent, // Varsayılan tema rengi
      companyAddress: json['companyAddress'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      contactFax: json['contactFax'] ?? '',
      contactMobile: json['contactMobile'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      contactWebsite: json['contactWebsite'] ?? '',
      invoiceHeader: json['invoiceHeader'] ?? 'FATURA',
      invoiceNumberPrefix: json['invoiceNumberPrefix'] ?? '',
      defaultTaxRate: (json['defaultTaxRate'] as num?)?.toDouble() ?? 18.0,
      defaultCurrency: json['defaultCurrency'] ?? '₺',
      defaultPaymentTerms: json['defaultPaymentTerms'] ?? 'Net 30 Gün',
      invoiceFooter: json['invoiceFooter'] ?? 'Teşekkür Ederiz.',
      footerCompanyName: json['footerCompanyName'] ?? '',
      footerAddress: json['footerAddress'] ?? '',
      footerPhone: json['footerPhone'] ?? '',
      footerFax: json['footerFax'] ?? '',
      footerEmail: json['footerEmail'] ?? '',
      bankName: json['bankName'] ?? '',
      iban: json['iban'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      financeOffice: json['financeOffice'] ?? '',
      pdfFontFamily: json['pdfFontFamily'], // JSON'dan okuma
      pdfTextColor: json['pdfTextColor'], // JSON'dan okuma
    );
  }

  // CompanySettings nesnesini JSON'a veya Map'e dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyDescription': companyDescription,
      'logoPath': logoPath,
      'themeColor': themeColor?.value,
      'companyAddress': companyAddress,
      'contactPhone': contactPhone,
      'contactFax': contactFax,
      'contactMobile': contactMobile,
      'contactEmail': contactEmail,
      'contactWebsite': contactWebsite,
      'invoiceHeader': invoiceHeader,
      'invoiceNumberPrefix': invoiceNumberPrefix,
      'defaultTaxRate': defaultTaxRate,
      'defaultCurrency': defaultCurrency,
      'defaultPaymentTerms': defaultPaymentTerms,
      'invoiceFooter': invoiceFooter,
      'footerCompanyName': footerCompanyName,
      'footerAddress': footerAddress,
      'footerPhone': footerPhone,
      'footerFax': footerFax,
      'footerEmail': footerEmail,
      'bankName': bankName,
      'iban': iban,
      'taxNumber': taxNumber,
      'financeOffice': financeOffice,
      'pdfFontFamily': pdfFontFamily, // JSON'a yazma
      'pdfTextColor': pdfTextColor, // JSON'a yazma
    };
  }

  // Varsayılan ayarları döndüren fabrika kurucusu
  factory CompanySettings.defaultSettings() {
    return CompanySettings(
      companyName: "MyService Company",
      companyDescription: "Profesyonel Hizmetleriniz için.",
      logoPath: null,
      themeColor: AppColors.yellowAccent,
      companyAddress: "123 Main St, Anytown TR",
      contactPhone: "+90 5XX XXX XX XX",
      contactFax: "",
      contactMobile: "",
      contactEmail: "info@myservice.com",
      contactWebsite: "",
      invoiceHeader: "FATURA",
      invoiceNumberPrefix: "INV-",
      defaultTaxRate: 18.0,
      defaultCurrency: "₺",
      defaultPaymentTerms: "Net 30 Gün",
      invoiceFooter:
          "Ödemeleriniz için teşekkür ederiz. Herhangi bir sorunuz olursa lütfen bizimle iletişime geçin.",
      footerCompanyName: "MyService Company",
      footerAddress: "123 Main St, Anytown TR",
      footerPhone: "+90 5XX XXX XX XX",
      footerFax: "",
      footerEmail: "info@myservice.com",
      bankName: "Your Bank Name",
      iban: "TRXX XXXX XXXX XXXX XXXX XXXX XX",
      taxNumber: "123 456 7890",
      financeOffice: "Your Tax Office",
      pdfFontFamily: 'Open Sans', // Varsayılan PDF yazı tipi
      pdfTextColor: Colors.black.value, // Varsayılan PDF yazı tipi rengi
    );
  }

  // Ayarları kolayca güncellemek için copyWith metodu
  CompanySettings copyWith({
    String? companyName,
    String? companyDescription,
    String? logoPath,
    Color? themeColor,
    String? companyAddress,
    String? contactPhone,
    String? contactFax,
    String? contactMobile,
    String? contactEmail,
    String? contactWebsite,
    String? invoiceHeader,
    String? invoiceNumberPrefix,
    double? defaultTaxRate,
    String? defaultCurrency,
    String? defaultPaymentTerms,
    String? invoiceFooter,
    String? footerCompanyName,
    String? footerAddress,
    String? footerPhone,
    String? footerFax,
    String? footerEmail,
    String? bankName,
    String? iban,
    String? taxNumber,
    String? financeOffice,
    String? pdfFontFamily,
    int? pdfTextColor,
  }) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      logoPath: logoPath ?? this.logoPath,
      themeColor: themeColor ?? this.themeColor,
      companyAddress: companyAddress ?? this.companyAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      contactFax: contactFax ?? this.contactFax,
      contactMobile: contactMobile ?? this.contactMobile,
      contactEmail: contactEmail ?? this.contactEmail,
      contactWebsite: contactWebsite ?? this.contactWebsite,
      invoiceHeader: invoiceHeader ?? this.invoiceHeader,
      invoiceNumberPrefix: invoiceNumberPrefix ?? this.invoiceNumberPrefix,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultPaymentTerms: defaultPaymentTerms ?? this.defaultPaymentTerms,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      footerCompanyName: footerCompanyName ?? this.footerCompanyName,
      footerAddress: footerAddress ?? this.footerAddress,
      footerPhone: footerPhone ?? this.footerPhone,
      footerFax: footerFax ?? this.footerFax,
      footerEmail: footerEmail ?? this.footerEmail,
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      taxNumber: taxNumber ?? this.taxNumber,
      financeOffice: financeOffice ?? this.financeOffice,
      pdfFontFamily: pdfFontFamily ?? this.pdfFontFamily,
      pdfTextColor: pdfTextColor ?? this.pdfTextColor,
    );
  }
}
