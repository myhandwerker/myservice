import 'package:google_ml_kit/google_ml_kit.dart';
import 'customer_material_model.dart';

/// Fotoğraftan metin okur (OCR)
Future<String> recognizeTextFromImage(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = GoogleMlKit.vision.textRecognizer();
  final RecognizedText recognizedText = await textRecognizer.processImage(
    inputImage,
  );
  await textRecognizer.close();
  return recognizedText.text;
}

/// OCR metninden malzeme listesi çıkartır.
/// - Satırdan miktar, birim, ad, fiyat yakalamaya çalışır.
/// - Eğer eksikse kalan alanları boş bırakır.
/// - Türkçe, Almanca, İngilizce fişleri destekler.
List<CustomerMaterial> parseMaterialsFromText(String ocrText) {
  final lines = ocrText
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final List<CustomerMaterial> materials = [];

  final excludeKeywords = [
    "toplam",
    "genel toplam",
    "ara toplam",
    "kdv",
    "tutar",
    "ödeme",
    "nakit",
    "kart",
    "fiş",
    "fatura",
    "barkod",
    "indirim",
    "adisyon",
    "para üstü",
    "gesamt",
    "summe",
    "betrag",
    "mwst",
    "ust",
    "netto",
    "bar",
    "wechselgeld",
    "zahlung",
    "rückgeld",
    "total",
    "subtotal",
    "vat",
    "tax",
    "amount",
    "cash",
    "change",
    "invoice",
    "barcode",
    "qr",
    "iban",
    "konto",
    "payment",
    "eur",
    "tl",
    "usd",
    "öffnungszeiten",
    "zeiten",
    "ust-id",
    "vielen dank",
    "gutes für alle",
    "grill",
    "preis",
    "sommer",
    "entdecke",
    "einkauf",
    "danke",
    "tse",
    "start:",
    "ende:",
    "sig.",
  ];

  final priceRegex = RegExp(r'(\d{1,5}[.,]\d{2})');
  // Miktar Birim Ad Fiyat (örn: "2 kg Elma 45,00")
  final qtyUnitNamePriceRegex = RegExp(
    r'^(\d{1,4})\s*([a-zA-Z\.]*)[\s\-:]+([a-zA-Z0-9 ,\-]{2,})[\s\-:]+(\d{1,5}[.,]\d{2})',
    caseSensitive: false,
  );
  // Ad Miktar Birim Fiyat (örn: "Elma 2 kg 45,00")
  final nameQtyUnitPriceRegex = RegExp(
    r'^([a-zA-Z0-9 ,\-]{2,})\s+(\d{1,4})\s*([a-zA-Z\.]*)\s+(\d{1,5}[.,]\d{2})',
    caseSensitive: false,
  );
  // Ad Fiyat (örn: "Elma 45,00")
  final namePriceRegex = RegExp(
    r'^([a-zA-Z0-9 ,\-]{2,})\s+(\d{1,5}[.,]\d{2})',
    caseSensitive: false,
  );

  String? lastName;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lline = line.toLowerCase();

    if (excludeKeywords.any((kw) => lline.contains(kw))) continue;
    if (line.replaceAll(RegExp(r'[^0-9]'), '').length > 10)
      continue; // barcode/seri

    // 1. Miktar Birim Ad Fiyat
    final match1 = qtyUnitNamePriceRegex.firstMatch(line);
    if (match1 != null) {
      final qty = double.tryParse(match1.group(1)!);
      final unit = match1.group(2) ?? "";
      final name = match1.group(3)?.trim() ?? "";
      final price = double.tryParse(match1.group(4)!.replaceAll(',', '.'));
      if (name.length > 1 && price != null && qty != null) {
        materials.add(
          CustomerMaterial(
            name: name,
            quantity: qty,
            unit: unit,
            price: price,
            note: null,
          ),
        );
        continue;
      }
    }

    // 2. Ad Miktar Birim Fiyat
    final match2 = nameQtyUnitPriceRegex.firstMatch(line);
    if (match2 != null) {
      final name = match2.group(1)?.trim() ?? "";
      final qty = double.tryParse(match2.group(2)!);
      final unit = match2.group(3) ?? "";
      final price = double.tryParse(match2.group(4)!.replaceAll(',', '.'));
      if (name.length > 1 && price != null && qty != null) {
        materials.add(
          CustomerMaterial(
            name: name,
            quantity: qty,
            unit: unit,
            price: price,
            note: null,
          ),
        );
        continue;
      }
    }

    // 3. Ad Fiyat
    final match3 = namePriceRegex.firstMatch(line);
    if (match3 != null) {
      final name = match3.group(1)?.trim() ?? "";
      final price = double.tryParse(match3.group(2)!.replaceAll(',', '.'));
      if (name.length > 1 && price != null) {
        materials.add(
          CustomerMaterial(
            name: name,
            quantity: 1,
            unit: "",
            price: price,
            note: null,
          ),
        );
        continue;
      }
    }

    // 4. Sadece fiyatlı satır (önceki satırı ad kabul et)
    final priceOnlyMatch = priceRegex.firstMatch(line);
    if (priceOnlyMatch != null && lastName != null) {
      final price = double.tryParse(
        priceOnlyMatch.group(1)!.replaceAll(',', '.'),
      );
      if (price != null) {
        materials.add(
          CustomerMaterial(
            name: lastName,
            quantity: 1,
            unit: "",
            price: price,
            note: null,
          ),
        );
        lastName = null;
        continue;
      }
    }

    // 5. Potansiyel ad satırı (sonraki satırda fiyat arayacağız)
    if (line.length > 2 &&
        line.replaceAll(RegExp(r'[^a-zA-Z ]'), '').length > 2) {
      lastName = line;
      continue;
    }
  }
  return materials;
}
