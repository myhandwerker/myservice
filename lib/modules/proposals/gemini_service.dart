// lib/modules/proposals/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // 👇 ÇOK ÖNEMLİ: BURAYA KENDİ GEÇERLİ GEMINI API ANAHTARINIZI YAPIŞTIRIN!
  // Bu örnekteki 'AIzaSyDfghlEi7LkfBLunB4yVOlC4RC3anQjxgQ' sadece bir yer tutucudur.
  // Google AI Studio'dan (https://aistudio.google.com/app/apikey) aldığınız gerçek API anahtarını buraya yapıştırmalısınız.
  // Üretim ortamında API anahtarını doğrudan koda yazmak güvenlik riski taşır, ancak şimdilik ilerlemek için bu şekilde devam ediyoruz.
  static const String apiKey = 'AIzaSyCWL2-z60VIsYIOGf3QkuFUitssSNwJjAs';

  static Future<Map<String, String>> analyzeMessageAndGenerateProposal({
    required String message,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final prompt =
        '''
Aşağıda bir müşterinin hizmet talebi mesajı var. 
Sen bir profesyonel teklif oluşturma asistanısın. 
Bu müşteri mesajına yanıt olarak, ona sunulacak **GİRİŞ, GELİŞME ve SONUÇ** başlıklarını içeren, açıklayıcı ve kibar bir **TEKLİF METNİ** oluşturmalısın. 
Bu teklif metni, doğrudan müşteriye gönderilebilecek bir formatta olmalıdır.
Fiyat veya tutar bilgisi belirtmeyin.
Metin Türkçe ve profesyonel olsun.

**ÖNEMLİ:** Teklif metninin içinde 'GİRİŞ', 'GELİŞME' ve 'SONUÇ' başlıklarını KULLANMAYIN. Bunlar sadece metnin yapısal rehberleridir.

Sadece aşağıdaki gibi, JSON formatında yanıt ver:

```json
{
  "customer": "(Müşteri adını ve soyadını bu mesajdan çıkarın. Eğer isim belirtilmemişse 'Değerli Müşterimiz' gibi genel bir ifade kullanın)",
  "request": "(Müşterinin iş talebini kısa ve net bir şekilde özetleyin)",
  "description": "(**Bu alan, müşteriye özel olarak hazırlanmış ve ona gönderilecek profesyonel teklif metnini içermelidir.** GİRİŞ, GELİŞME ve SONUÇ bölümlerini içerdiğinden emin olun. Giriş, selam ve talebe teşekkürle başlasın. Gelişme, hizmeti ve çözümü detaylandırsın. Sonuç, iletişim ve kapanış cümlesi olsun. Fiyat belirtmeyiniz.)"
}
```

Mesaj:
$message
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          var content =
              candidates[0]?['content']?['parts']?[0]?['text']
                  ?.toString()
                  .trim() ??
              '';
          final regex = RegExp(r'```(?:json)?([\s\S]*?)```', multiLine: true);
          final match = regex.firstMatch(content);
          if (match != null) {
            content = match.group(1)?.trim() ?? content.trim();
          } else {
            final jsonMatch = RegExp(r'(\{[\s\S]*\})').firstMatch(content);
            if (jsonMatch != null) {
              content = jsonMatch.group(1)!.trim();
            }
          }
          try {
            final parsed = jsonDecode(content);
            return {
              "customer": parsed["customer"] ?? "",
              "request": parsed["request"] ?? "",
              "description": parsed["description"] ?? "",
            };
          } catch (e) {
            print('Gemini JSON parse hatası: $e\nGelen içerik: $content');
            throw Exception('Gemini yanıtı beklenen JSON formatında değil.');
          }
        } else {
          throw Exception(
            'Gemini API: Yanıt alınamadı veya boş aday döndürüldü!',
          );
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('Gemini yanıt hatası: ${response.statusCode} - $errorBody');
        throw Exception(
          'Gemini mesaj analiz ve teklif üretilemedi. Durum Kodu: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Gemini API isteği sırasında hata oluştu: $e');
      throw Exception('AI servisine bağlanılamadı: ${e.toString()}');
    }
  }
}
