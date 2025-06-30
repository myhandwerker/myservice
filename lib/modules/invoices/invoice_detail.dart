// lib/modules/invoices/invoice_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // printing paketi hala gerekli
import 'package:path_provider/path_provider.dart'; // getTemporaryDirectory için gerekli
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart'
    show rootBundle; // Font dosyasını yüklemek için gerekli
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io show File;

import '../../utils/constants.dart';
import 'invoice_model.dart';
import 'invoice_item_model.dart';
import '../customers/customer_model.dart';
import '../settings/company_settings_model.dart';

class InvoiceDetail extends StatelessWidget {
  final Invoice invoice;
  final CompanySettings companySettings;
  final Customer customer;

  const InvoiceDetail({
    super.key,
    required this.invoice,
    required this.companySettings,
    required this.customer, // <<< BU SATIR DÜZELTİLDİ!
  });

  String _getItemTypeDisplayName(InvoiceItemType t) {
    switch (t) {
      case InvoiceItemType.material:
        return "Malzeme";
      case InvoiceItemType.workHour:
        return "İşçilik";
      case InvoiceItemType.kilometerCost:
        return "Seyahat";
      case InvoiceItemType.other:
        return "Diğer";
    }
  }

  // Ayarlardan gelen PDF metin rengini kullan
  PdfColor _getEffectivePdfTextColor() {
    if (companySettings.pdfTextColor != null) {
      return PdfColor.fromInt(companySettings.pdfTextColor!);
    }
    return PdfColors.black; // Varsayılan olarak siyah
  }

  // Tema rengini PDF rengine dönüştürür (başlıklar, çizgiler için)
  PdfColor _toPdfAccentColor(Color color) {
    return PdfColor.fromInt(color.value);
  }

  // Font dosyasını assets'ten yükleyen fonksiyon
  Future<pw.Font> _loadFontFromAssets(String fontPath) async {
    try {
      final ByteData bytes = await rootBundle.load(fontPath);
      return pw.Font.ttf(bytes.buffer.asByteData());
    } catch (e) {
      print(
          "Uyarı: Font dosyası yüklenirken hata oluştu: $fontPath, Hata: $e. Helvetica kullanılıyor.");
      return pw.Font.helvetica(); // Hata durumunda varsayılan Helvetica fontu
    }
  }

  Future<Uint8List> _generatePdfContent() async {
    final pdf = pw.Document();

    // PDF için yazı tipini yükle
    // companySettings.pdfFontFamily değeri (örneğin "OpenSans-Regular.ttf") kullanılacak.
    // Eğer companySettings.pdfFontFamily boşsa veya null ise, varsayılan bir font yolu verin.
    final String actualFontPath = companySettings.pdfFontFamily != null &&
            companySettings.pdfFontFamily!.isNotEmpty
        ? 'assets/fonts/${companySettings.pdfFontFamily}' // Varsayılan olarak assets/fonts içinde arıyoruz
        : 'assets/fonts/OpenSans-Regular.ttf'; // Varsayılan font yolu

    final pw.Font pdfCustomFont = await _loadFontFromAssets(actualFontPath);

    pw.MemoryImage? companyLogo;
    String? effectiveLogoPath = companySettings.logoPath;

    if (effectiveLogoPath != null && effectiveLogoPath.isNotEmpty) {
      // Asset klasöründen yüklemeyi dene
      try {
        final ByteData bytes = await rootBundle.load(effectiveLogoPath);
        companyLogo = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        print("PDF için logo yüklenirken hata oluştu (asset olarak): $e");
        // Asset olarak bulunamazsa, eğer mobil veya masaüstü ise dosya sisteminden dene
        if (!kIsWeb) {
          try {
            final file = io.File(effectiveLogoPath);
            if (file.existsSync()) {
              final fileBytes = await file.readAsBytes();
              companyLogo = pw.MemoryImage(fileBytes);
            }
          } catch (fileError) {
            print(
                "PDF için dosya logosu yüklenirken hata oluştu (dosya olarak): $fileError");
          }
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Firma Bilgileri
              pw.Center(
                child: pw.Column(
                  children: [
                    if (companyLogo != null) pw.Image(companyLogo, height: 56),
                    pw.Text(
                      companySettings.companyName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: pdfCustomFont, // Font uygulandı
                        color: _toPdfAccentColor(companySettings.themeColor!),
                      ),
                    ),
                    pw.Text(
                      companySettings.companyAddress,
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    pw.Text(
                      "Vergi No: ${companySettings.taxNumber}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    pw.Text(
                      companySettings.contactPhone,
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    if (companySettings.contactFax.isNotEmpty)
                      pw.Text(
                        "Faks: ${companySettings.contactFax}",
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    if (companySettings.contactMobile.isNotEmpty)
                      pw.Text(
                        "Mobil: ${companySettings.contactMobile}",
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    pw.Text(
                      companySettings.contactEmail,
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    if (companySettings.contactWebsite.isNotEmpty)
                      pw.Text(
                        "Web: ${companySettings.contactWebsite}",
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      companySettings.invoiceHeader,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        font: pdfCustomFont, // Font uygulandı
                        color: _toPdfAccentColor(companySettings.themeColor!),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(
                height: 32,
                color: _toPdfAccentColor(companySettings.themeColor!),
              ),

              // Müşteri Bilgileri
              pw.Text(
                "Müşteri Bilgileri",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: pdfCustomFont, // Font uygulandı
                  color: _toPdfAccentColor(companySettings.themeColor!),
                ),
              ),
              pw.Text(
                customer.name,
                style: pw.TextStyle(
                  fontSize: 12,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              pw.Text(
                customer.address,
                style: pw.TextStyle(
                  fontSize: 10,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              pw.Text(
                "Müşteri No: ${customer.customerNumber ?? 'Belirtilmedi'}",
                style: pw.TextStyle(
                  fontSize: 10,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              pw.Text(
                customer.phone,
                style: pw.TextStyle(
                  fontSize: 10,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              pw.Text(
                customer.email,
                style: pw.TextStyle(
                  fontSize: 10,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              pw.SizedBox(height: AppConstants.padding),

              // Temel Fatura Bilgileri
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      "Fatura No: ${companySettings.invoiceNumberPrefix}${invoice.invoiceNumber}", // Prefix eklendi
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      "Tarih: ${DateFormat('dd.MM.yyyy').format(invoice.issueDate)}",
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                  ),
                ],
              ),
              if (invoice.dueDate != null)
                pw.Text(
                  "Vade Tarihi: ${DateFormat('dd.MM.yyyy').format(invoice.dueDate!)}",
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: pdfCustomFont, // Font uygulandı
                    color: _getEffectivePdfTextColor(),
                  ),
                ),
              pw.Text(
                "Durum: ${invoice.status.displayName}",
                style: pw.TextStyle(
                  fontSize: 12,
                  font: pdfCustomFont, // Font uygulandı
                  color: _toPdfAccentColor(invoice.status.displayColor),
                ),
              ),
              pw.Text(
                "Ödeme Koşulları: ${companySettings.defaultPaymentTerms}", // Default ödeme şartı
                style: pw.TextStyle(
                  fontSize: 12,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                ),
              ),
              if (invoice.description != null &&
                  invoice.description!.isNotEmpty)
                pw.Text(
                  "Açıklama: ${invoice.description!}",
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: pdfCustomFont, // Font uygulandı
                    color: _getEffectivePdfTextColor(),
                  ),
                ),
              pw.SizedBox(height: AppConstants.padding),

              // Fatura Kalemleri (Table ile daha düzenli)
              pw.Text(
                "Fatura Kalemleri",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: pdfCustomFont, // Font uygulandı
                  color: _toPdfAccentColor(companySettings.themeColor!),
                ),
              ),
              pw.Table.fromTextArray(
                headers: ['Açıklama', 'Tip', 'Miktar', 'Birim Fiyat', 'Toplam'],
                data: invoice.items.map((item) {
                  return [
                    item.description,
                    _getItemTypeDisplayName(item.type),
                    "${item.quantity} ${item.unit}",
                    "${item.unitPrice.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                    "${item.total.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                  fontSize: 10,
                ),
                cellStyle: pw.TextStyle(
                  font: pdfCustomFont, // Font uygulandı
                  color: _getEffectivePdfTextColor(),
                  fontSize: 10,
                ),
                border: pw.TableBorder.all(
                  color: _toPdfAccentColor(AppColors.divider),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
              ),
              pw.SizedBox(height: AppConstants.padding),

              // Toplamlar
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Ara Toplam: ${invoice.subtotal.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    pw.Text(
                      "İndirim: -${invoice.discount.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    pw.Text(
                      "Vergi (${invoice.taxRate}%): +${invoice.totalTax.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: pdfCustomFont, // Font uygulandı
                        color: _getEffectivePdfTextColor(),
                      ),
                    ),
                    pw.Divider(color: _toPdfAccentColor(AppColors.divider)),
                    pw.Text(
                      "Genel Toplam: ${invoice.totalAmount.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        font: pdfCustomFont, // Font uygulandı
                        color: _toPdfAccentColor(companySettings.themeColor!),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: AppConstants.padding),

              // Dipnotlar (Footer bilgileri eklendi)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      companySettings.invoiceFooter,
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: pdfCustomFont,
                        color: _getEffectivePdfTextColor(),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    if (companySettings.footerCompanyName.isNotEmpty)
                      pw.Text(
                        companySettings.footerCompanyName,
                        style: pw.TextStyle(
                          fontSize: 9,
                          font: pdfCustomFont,
                          fontWeight: pw.FontWeight.bold,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    if (companySettings.footerAddress.isNotEmpty)
                      pw.Text(
                        companySettings.footerAddress,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    if (companySettings.footerPhone.isNotEmpty ||
                        companySettings.footerFax.isNotEmpty ||
                        companySettings.footerEmail.isNotEmpty)
                      pw.Text(
                        "Telefon: ${companySettings.footerPhone} ${companySettings.footerFax.isNotEmpty ? '| Faks: ${companySettings.footerFax}' : ''} ${companySettings.footerEmail.isNotEmpty ? '| E-posta: ${companySettings.footerEmail}' : ''}",
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    if (companySettings.bankName.isNotEmpty ||
                        companySettings.iban.isNotEmpty)
                      pw.Text(
                        "Banka: ${companySettings.bankName} ${companySettings.iban.isNotEmpty ? '| IBAN: ${companySettings.iban}' : ''}",
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                    if (companySettings.taxNumber.isNotEmpty ||
                        companySettings.financeOffice.isNotEmpty)
                      pw.Text(
                        "Vergi No: ${companySettings.taxNumber} ${companySettings.financeOffice.isNotEmpty ? '| Vergi Dairesi: ${companySettings.financeOffice}' : ''}",
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: pdfCustomFont,
                          color: _getEffectivePdfTextColor(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _exportInvoiceToPdf(BuildContext context) async {
    try {
      final pdfBytes = await _generatePdfContent();

      if (kIsWeb) {
        await Printing.sharePdf(
            bytes: pdfBytes, filename: 'fatura_${invoice.invoiceNumber}.pdf');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fatura PDF olarak indirildi!"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // getTemporaryDirectory() burada doğru bir şekilde çağrılıyor (path_provider'dan)
        final output = await getTemporaryDirectory();
        final file =
            io.File("${output.path}/fatura_${invoice.invoiceNumber}.pdf");
        await file.writeAsBytes(pdfBytes);

        if (context.mounted) {
          await Share.shareXFiles([
            XFile(file.path),
          ], text: "Fatura: ${invoice.invoiceNumber}");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Fatura PDF olarak dışarı aktarıldı ve paylaşma ekranı açıldı!",
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("PDF dışarı aktarılırken hata oluştu: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await _generatePdfContent();
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fatura yazdırma ekranı açıldı!"),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fatura yazdırılırken hata oluştu: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    await _exportInvoiceToPdf(context);
  }

  @override
  Widget build(BuildContext context) {
    final String? currentLogoPath = companySettings.logoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Fatura Detayı",
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.yellowAccent,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: AppColors.yellowAccent,
            ),
            onPressed: () => _exportInvoiceToPdf(context),
            tooltip: 'PDF Olarak Aktar ve Paylaş',
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.yellowAccent),
            onPressed: () => _printInvoice(context),
            tooltip: 'Yazdır',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.yellowAccent),
            onPressed: () => _shareInvoice(context),
            tooltip: 'Faturayı Paylaş',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firma Bilgileri
            Center(
              child: Column(
                children: [
                  (currentLogoPath != null && currentLogoPath.isNotEmpty)
                      ? kIsWeb
                          ? Image.network(
                              currentLogoPath,
                              height: 56,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.business,
                                      size: 56, color: AppColors.yellowAccent),
                            )
                          : (io.File(currentLogoPath).existsSync()
                              ? Image.file(
                                  io.File(currentLogoPath),
                                  height: 56,
                                )
                              : const Icon(Icons.business,
                                  size: 56, color: AppColors.yellowAccent))
                      : const Icon(
                          Icons.business,
                          size: 56,
                          color: AppColors.yellowAccent,
                        ),
                  Text(
                    companySettings.companyName,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.yellowAccent,
                    ),
                  ),
                  Text(
                    companySettings.companyAddress,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Vergi No: ${companySettings.taxNumber}",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    companySettings.contactPhone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (companySettings.contactFax.isNotEmpty)
                    Text(
                      "Faks: ${companySettings.contactFax}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (companySettings.contactMobile.isNotEmpty)
                    Text(
                      "Mobil: ${companySettings.contactMobile}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  Text(
                    companySettings.contactEmail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (companySettings.contactWebsite.isNotEmpty)
                    Text(
                      "Web: ${companySettings.contactWebsite}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    companySettings.invoiceHeader,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.yellowAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: AppColors.yellowAccent),

            // Müşteri Bilgileri
            Text(
              "Müşteri Bilgileri",
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.yellowAccent,
              ),
            ),
            Text(
              customer.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              customer.address,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              customer.phone,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              customer.email,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding),

            // Temel Fatura Bilgileri
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Fatura No: ${companySettings.invoiceNumberPrefix}${invoice.invoiceNumber}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Tarih: ${DateFormat('dd.MM.yyyy').format(invoice.issueDate)}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (invoice.dueDate != null)
              Text(
                "Vade Tarihi: ${DateFormat('dd.MM.yyyy').format(invoice.dueDate!)}",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            Text(
              "Durum: ${invoice.status.displayName}",
              style: AppTextStyles.bodyMedium.copyWith(
                color: invoice.status.displayColor,
              ),
            ),
            Text(
              "Ödeme Koşulları: ${companySettings.defaultPaymentTerms}",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (invoice.description != null && invoice.description!.isNotEmpty)
              Text(
                "Açıklama: ${invoice.description!}",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: AppConstants.padding),

            // Fatura Kalemleri (Card ve Padding ile daha iyi görünüm)
            Text(
              "Fatura Kalemleri",
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.yellowAccent,
              ),
            ),
            Card(
              color: AppColors.surface,
              margin: const EdgeInsets.symmetric(
                vertical: AppConstants.padding / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Column(
                  children: [
                    // Başlık Satırı
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Açıklama',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Tip',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Miktar',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Birim Fiyat',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Toplam',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.divider),
                    // Kalemler
                    ...invoice.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _getItemTypeDisplayName(item.type),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "${item.quantity} ${item.unit}",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "${item.unitPrice.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "${item.total.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.yellowAccent,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padding),

            // Toplamlar
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Ara Toplam: ${invoice.subtotal.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "İndirim: -${invoice.discount.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Vergi (${invoice.taxRate}%): +${invoice.totalTax.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    Text(
                      "Genel Toplam: ${invoice.totalAmount.toStringAsFixed(2)} ${companySettings.defaultCurrency}",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.yellowAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padding),

            // Dipnot (Footer bilgileri)
            Center(
              child: Column(
                children: [
                  Text(
                    companySettings.invoiceFooter,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (companySettings.footerCompanyName.isNotEmpty)
                    Text(
                      companySettings.footerCompanyName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (companySettings.footerAddress.isNotEmpty)
                    Text(
                      companySettings.footerAddress,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (companySettings.footerPhone.isNotEmpty ||
                      companySettings.footerFax.isNotEmpty ||
                      companySettings.footerEmail.isNotEmpty)
                    Text(
                      "Telefon: ${companySettings.footerPhone} ${companySettings.footerFax.isNotEmpty ? '| Faks: ${companySettings.footerFax}' : ''} ${companySettings.footerEmail.isNotEmpty ? '| E-posta: ${companySettings.footerEmail}' : ''}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (companySettings.bankName.isNotEmpty ||
                      companySettings.iban.isNotEmpty)
                    Text(
                      "Banka: ${companySettings.bankName} ${companySettings.iban.isNotEmpty ? '| IBAN: ${companySettings.iban}' : ''}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (companySettings.taxNumber.isNotEmpty ||
                      companySettings.financeOffice.isNotEmpty)
                    Text(
                      "Vergi No: ${companySettings.taxNumber} ${companySettings.financeOffice.isNotEmpty ? '| Vergi Dairesi: ${companySettings.financeOffice}' : ''}",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
