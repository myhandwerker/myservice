// lib/modules/settings/company_customization_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Renk seçici için import edildi
import 'package:flutter/foundation.dart' show kIsWeb; // Web için File kontrolü
import 'dart:io'; // File sınıfı için (kIsWeb'e göre değişir)

import '../../utils/constants.dart'; // AppConstants ve AppTextStyles için
import 'company_settings_model.dart';

class CompanyCustomizationPage extends StatefulWidget {
  final CompanySettings companySettings;
  final void Function(CompanySettings) onCompanySettingsChanged;

  const CompanyCustomizationPage({
    super.key,
    required this.companySettings,
    required this.onCompanySettingsChanged,
  });

  @override
  State<CompanyCustomizationPage> createState() =>
      _CompanyCustomizationPageState();
}

class _CompanyCustomizationPageState extends State<CompanyCustomizationPage> {
  // Şirket Bilgileri
  late String _companyName;
  late String? _companyDescription;
  String? _logoPath; // Logo yolu, File yerine String olarak tutulacak
  final _formCompany = GlobalKey<FormState>();

  // Tema Ayarları
  late Color _themeColor;

  // Fatura Ayarları
  late String _companyAddress;
  late String _contactPhone;
  late String _contactFax;
  late String _contactMobile;
  late String _contactEmail;
  late String _contactWebsite;
  late String _invoiceHeader;
  late String _invoiceNumberPrefix;
  late double _defaultTaxRate;
  late String _defaultCurrency;
  late String _defaultPaymentTerms;
  late String _invoiceFooter;
  final _formInvoice = GlobalKey<FormState>();

  // Footer Bilgileri
  late String _footerCompanyName;
  late String _footerAddress;
  late String _footerPhone;
  late String _footerFax;
  late String _footerEmail;
  late String _bankName;
  late String _iban;
  late String _taxNumber;
  late String _financeOffice;
  final _formFooter = GlobalKey<FormState>();

  // PDF Özelleştirme Ayarları
  String? _selectedPdfFontFamily; // PDF yazı tipi ailesi için
  late Color _currentPdfTextColor; // PDF metin rengi için

  final List<String> _availablePdfFonts = [
    'Open Sans', 'Lato', 'Roboto', 'Noto Sans', 'Montserrat', 'Merriweather',
    'Inter', 'Times New Roman', 'Arial' // Daha fazla popüler font
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.companySettings;
    _companyName = s.companyName;
    _companyDescription = s.companyDescription;
    _logoPath = s.logoPath;
    _themeColor = s.themeColor ?? AppColors.yellowAccent;

    _companyAddress = s.companyAddress;
    _contactPhone = s.contactPhone;
    _contactFax = s.contactFax;
    _contactMobile = s.contactMobile;
    _contactEmail = s.contactEmail;
    _contactWebsite = s.contactWebsite;
    _invoiceHeader = s.invoiceHeader;
    _invoiceNumberPrefix = s.invoiceNumberPrefix;
    _defaultTaxRate = s.defaultTaxRate;
    _defaultCurrency = s.defaultCurrency;
    _defaultPaymentTerms = s.defaultPaymentTerms;
    _invoiceFooter = s.invoiceFooter;
    _footerCompanyName = s.footerCompanyName;
    _footerAddress = s.footerAddress;
    _footerPhone = s.footerPhone;
    _footerFax = s.footerFax;
    _footerEmail = s.footerEmail;
    _bankName = s.bankName;
    _iban = s.iban;
    _taxNumber = s.taxNumber;
    _financeOffice = s.financeOffice;

    _selectedPdfFontFamily = s.pdfFontFamily;
    _currentPdfTextColor = Color(s.pdfTextColor ?? Colors.black.value);
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Eğer web dışındaysak (mobil/masaüstü), File objesinin path'ini kaydet
      if (!kIsWeb) {
        setState(() {
          _logoPath = pickedFile.path;
        });
      } else {
        // Web'de File path'i doğrudan kullanılamaz,
        // ancak demo amaçlı veya sabit asset yolu olarak kabul edebiliriz.
        // Gerçek bir web uygulamasında, buraya bir URL veya base64 string gelmelidir.
        setState(() {
          _logoPath = pickedFile
              .path; // Web'de bu genelde geçici bir URL veya Blob URL'sidir.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Web'de logo yükleme farklı çalışabilir, sadece yol kaydedildi."),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  void _saveCompanyInfo() {
    if (_formCompany.currentState?.validate() ?? false) {
      _formCompany.currentState?.save();
      final updated = widget.companySettings.copyWith(
        companyName: _companyName,
        companyDescription: _companyDescription,
        logoPath: _logoPath,
        companyAddress: _companyAddress,
        contactPhone: _contactPhone,
        contactFax: _contactFax,
        contactMobile: _contactMobile,
        contactEmail: _contactEmail,
        contactWebsite: _contactWebsite,
      );
      widget.onCompanySettingsChanged(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Şirket bilgileri kaydedildi!"),
            backgroundColor: AppColors.success),
      );
    }
  }

  void _saveThemeColor(Color color) {
    setState(() => _themeColor = color);
    final updated = widget.companySettings.copyWith(themeColor: color);
    widget.onCompanySettingsChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Tema rengi kaydedildi!"),
          backgroundColor: AppColors.success),
    );
  }

  void _savePdfTextColor(Color color) {
    setState(() => _currentPdfTextColor = color);
    final updated = widget.companySettings.copyWith(pdfTextColor: color.value);
    widget.onCompanySettingsChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("PDF metin rengi kaydedildi!"),
          backgroundColor: AppColors.success),
    );
  }

  void _savePdfFontFamily(String? fontFamily) {
    setState(() => _selectedPdfFontFamily = fontFamily);
    final updated = widget.companySettings.copyWith(pdfFontFamily: fontFamily);
    widget.onCompanySettingsChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("PDF yazı tipi kaydedildi!"),
          backgroundColor: AppColors.success),
    );
  }

  void _saveInvoiceSettings() {
    if (_formInvoice.currentState?.validate() ?? false) {
      _formInvoice.currentState?.save();
      final updated = widget.companySettings.copyWith(
        invoiceHeader: _invoiceHeader,
        invoiceNumberPrefix: _invoiceNumberPrefix,
        defaultTaxRate: _defaultTaxRate,
        defaultCurrency: _defaultCurrency,
        defaultPaymentTerms: _defaultPaymentTerms,
        invoiceFooter: _invoiceFooter,
      );
      widget.onCompanySettingsChanged(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Fatura ayarları kaydedildi!"),
            backgroundColor: AppColors.success),
      );
    }
  }

  void _saveFooterSettings() {
    if (_formFooter.currentState?.validate() ?? false) {
      _formFooter.currentState?.save();
      final updated = widget.companySettings.copyWith(
        footerCompanyName: _footerCompanyName,
        footerAddress: _footerAddress,
        footerPhone: _footerPhone,
        footerFax: _footerFax,
        footerEmail: _footerEmail,
        bankName: _bankName,
        iban: _iban,
        taxNumber: _taxNumber,
        financeOffice: _financeOffice,
      );
      widget.onCompanySettingsChanged(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Sayfa altı bilgileri kaydedildi!"),
            backgroundColor: AppColors.success),
      );
    }
  }

  void _resetToFactoryDefaults() {
    final defaultSettings = CompanySettings.defaultSettings();

    setState(() {
      _companyName = defaultSettings.companyName;
      _companyDescription = defaultSettings.companyDescription;
      _logoPath = defaultSettings.logoPath;
      _themeColor = defaultSettings.themeColor ?? AppColors.yellowAccent;

      _companyAddress = defaultSettings.companyAddress;
      _contactPhone = defaultSettings.contactPhone;
      _contactFax = defaultSettings.contactFax;
      _contactMobile = defaultSettings.contactMobile;
      _contactEmail = defaultSettings.contactEmail;
      _contactWebsite = defaultSettings.contactWebsite;
      _invoiceHeader = defaultSettings.invoiceHeader;
      _invoiceNumberPrefix = defaultSettings.invoiceNumberPrefix;
      _defaultTaxRate = defaultSettings.defaultTaxRate;
      _defaultCurrency = defaultSettings.defaultCurrency;
      _defaultPaymentTerms = defaultSettings.defaultPaymentTerms;
      _invoiceFooter = defaultSettings.invoiceFooter;
      _footerCompanyName = defaultSettings.footerCompanyName;
      _footerAddress = defaultSettings.footerAddress;
      _footerPhone = defaultSettings.footerPhone;
      _footerFax = defaultSettings.footerFax;
      _footerEmail = defaultSettings.footerEmail;
      _bankName = defaultSettings.bankName;
      _iban = defaultSettings.iban;
      _taxNumber = defaultSettings.taxNumber;
      _financeOffice = defaultSettings.financeOffice;

      _selectedPdfFontFamily = defaultSettings.pdfFontFamily;
      _currentPdfTextColor =
          Color(defaultSettings.pdfTextColor ?? Colors.black.value);
    });

    widget.onCompanySettingsChanged(defaultSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Ayarlar fabrika ayarlarına döndürüldü!"),
          backgroundColor: AppColors.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // Uygulama genelinde koyu arka plan
      appBar: AppBar(
        title: Text(
          "Şirket Özelleştirmeleri",
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.yellowAccent),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Fabrika Ayarlarına Dön",
            icon: const Icon(Icons.restore, color: AppColors.yellowAccent),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface, // Dialog arka planı
                  title: Text("Fabrika Ayarlarına Dön",
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.textPrimary)),
                  content: Text(
                    "Tüm şirket ayarlarını sıfırlamak istediğinize emin misiniz?",
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("İptal",
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.yellowAccent)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Evet",
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _resetToFactoryDefaults();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          // Şirket Bilgileri Bölümü
          Card(
            // elevation: AppConstants.elevation, // <<< BU KALDIRILDI
            margin: const EdgeInsets.only(bottom: AppConstants.padding),
            color: AppColors.surface, // Kart arka planı
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formCompany,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business,
                            color: AppColors.yellowAccent),
                        const SizedBox(width: AppConstants.padding / 2),
                        Text(
                          "Şirket Bilgileri",
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.yellowAccent),
                        ),
                      ],
                    ),
                    const Divider(
                        height: AppConstants.padding * 1.5,
                        color: AppColors.divider),
                    _buildTextFormField(
                      initialValue: _companyName,
                      labelText: "Şirket Adı",
                      onSaved: (value) => _companyName = value ?? '',
                      validator: (value) => value == null || value.isEmpty
                          ? "Şirket adı giriniz"
                          : null,
                    ),
                    _buildTextFormField(
                      initialValue: _companyDescription,
                      labelText: "Şirket Açıklaması / Slogan",
                      minLines: 1,
                      maxLines: 3,
                      onSaved: (value) => _companyDescription = value,
                    ),
                    ListTile(
                      leading: _logoPath != null && _logoPath!.isNotEmpty
                          ? (kIsWeb
                              ? Image.network(_logoPath!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business,
                                          size: 48,
                                          color: AppColors.yellowAccent))
                              : Image.file(File(_logoPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business,
                                          size: 48,
                                          color: AppColors.yellowAccent)))
                          : const CircleAvatar(
                              child: Icon(Icons.business,
                                  color: AppColors.background)),
                      title: Text("Logo Seç",
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                      onTap: _pickLogo,
                      trailing: _logoPath != null && _logoPath!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.error),
                              tooltip: "Logoyu Kaldır",
                              onPressed: () => setState(() => _logoPath = null),
                            )
                          : null,
                    ),
                    _buildTextFormField(
                        initialValue: _companyAddress,
                        labelText: "Şirket Adresi",
                        onSaved: (value) => _companyAddress = value ?? ""),
                    _buildTextFormField(
                        initialValue: _contactPhone,
                        labelText: "Telefon",
                        onSaved: (value) => _contactPhone = value ?? ""),
                    _buildTextFormField(
                        initialValue: _contactFax,
                        labelText: "Fax",
                        onSaved: (value) => _contactFax = value ?? ""),
                    _buildTextFormField(
                        initialValue: _contactMobile,
                        labelText: "Mobil",
                        onSaved: (value) => _contactMobile = value ?? ""),
                    _buildTextFormField(
                        initialValue: _contactEmail,
                        labelText: "E-posta",
                        onSaved: (value) => _contactEmail = value ?? ""),
                    _buildTextFormField(
                        initialValue: _contactWebsite,
                        labelText: "Web",
                        onSaved: (value) => _contactWebsite = value ?? ""),
                    const SizedBox(height: AppConstants.padding),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:
                            const Icon(Icons.save, color: AppColors.background),
                        label: Text("Şirket Bilgilerini Kaydet",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.background)),
                        onPressed: _saveCompanyInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellowAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.padding),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tema ve PDF Ayarları Bölümü
          Card(
            // elevation: AppConstants.elevation, // <<< BU KALDIRILDI
            margin: const EdgeInsets.only(bottom: AppConstants.padding),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette, color: AppColors.yellowAccent),
                      const SizedBox(width: AppConstants.padding / 2),
                      Text(
                        "Görsel Ayarlar",
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.yellowAccent),
                      ),
                    ],
                  ),
                  const Divider(
                      height: AppConstants.padding * 1.5,
                      color: AppColors.divider),

                  // Tema Rengi Seçimi
                  ListTile(
                    title: Text('Tema Rengi',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    trailing:
                        CircleAvatar(backgroundColor: _themeColor, radius: 16),
                    onTap: () =>
                        _showColorPickerDialog(_themeColor, _saveThemeColor),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padding),

                  // PDF Yazı Tipi Ailesi Seçimi
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'PDF Yazı Tipi Ailesi',
                      labelStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(AppConstants.borderRadius)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.divider),
                        borderRadius: BorderRadius.all(
                            Radius.circular(AppConstants.borderRadius)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.yellowAccent, width: 2),
                        borderRadius: BorderRadius.all(
                            Radius.circular(AppConstants.borderRadius)),
                      ),
                    ),
                    value: _selectedPdfFontFamily,
                    dropdownColor:
                        AppColors.surface, // Dropdown arka plan rengi
                    items: _availablePdfFonts.map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(
                          font,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) =>
                        _savePdfFontFamily(newValue),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppConstants.padding),

                  // PDF Metin Rengi Seçimi
                  ListTile(
                    title: Text('PDF Metin Rengi',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    trailing: CircleAvatar(
                        backgroundColor: _currentPdfTextColor, radius: 16),
                    onTap: () => _showColorPickerDialog(
                        _currentPdfTextColor, _savePdfTextColor),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padding),
                ],
              ),
            ),
          ),

          // Fatura Ayarları Bölümü
          Card(
            // elevation: AppConstants.elevation, // <<< BU KALDIRILDI
            margin: const EdgeInsets.only(bottom: AppConstants.padding),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formInvoice,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            color: AppColors.yellowAccent),
                        const SizedBox(width: AppConstants.padding / 2),
                        Text(
                          "Fatura Ayarları",
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.yellowAccent),
                        ),
                      ],
                    ),
                    const Divider(
                        height: AppConstants.padding * 1.5,
                        color: AppColors.divider),
                    _buildTextFormField(
                        initialValue: _invoiceHeader,
                        labelText: "Fatura Başlığı",
                        onSaved: (value) => _invoiceHeader = value ?? "FATURA"),
                    _buildTextFormField(
                        initialValue: _invoiceNumberPrefix,
                        labelText: "Fatura No Ön Ek",
                        onSaved: (value) => _invoiceNumberPrefix = value ?? ""),
                    _buildTextFormField(
                        initialValue: _defaultTaxRate.toString(),
                        labelText: "Varsayılan KDV Oranı (%)",
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _defaultTaxRate =
                            double.tryParse(value ?? "") ?? 18.0),
                    _buildTextFormField(
                        initialValue: _defaultCurrency,
                        labelText: "Varsayılan Para Birimi",
                        onSaved: (value) => _defaultCurrency = value ?? "₺"),
                    _buildTextFormField(
                        initialValue: _defaultPaymentTerms,
                        labelText: "Varsayılan Vade (Ödeme Şartı)",
                        onSaved: (value) =>
                            _defaultPaymentTerms = value ?? "Net 30 Gün"),
                    _buildTextFormField(
                        initialValue: _invoiceFooter,
                        labelText: "Fatura Alt Metni",
                        onSaved: (value) =>
                            _invoiceFooter = value ?? "Teşekkür Ederiz.",
                        maxLines: 3),
                    const SizedBox(height: AppConstants.padding),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:
                            const Icon(Icons.save, color: AppColors.background),
                        label: Text("Fatura Ayarlarını Kaydet",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.background)),
                        onPressed: _saveInvoiceSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellowAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.padding),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sayfa Altı Bilgileri Bölümü
          Card(
            // elevation: AppConstants.elevation, // <<< BU KALDIRILDI
            margin: const EdgeInsets.only(bottom: AppConstants.padding),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formFooter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.yellowAccent),
                        const SizedBox(width: AppConstants.padding / 2),
                        Text(
                          "Sayfa Altı Bilgileri",
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.yellowAccent),
                        ),
                      ],
                    ),
                    const Divider(
                        height: AppConstants.padding * 1.5,
                        color: AppColors.divider),
                    _buildTextFormField(
                        initialValue: _footerCompanyName,
                        labelText: "Alt Firma Adı",
                        onSaved: (value) => _footerCompanyName = value ?? ""),
                    _buildTextFormField(
                        initialValue: _footerAddress,
                        labelText: "Alt Adres",
                        onSaved: (value) => _footerAddress = value ?? ""),
                    _buildTextFormField(
                        initialValue: _footerPhone,
                        labelText: "Alt Telefon",
                        onSaved: (value) => _footerPhone = value ?? ""),
                    _buildTextFormField(
                        initialValue: _footerFax,
                        labelText: "Alt Fax",
                        onSaved: (value) => _footerFax = value ?? ""),
                    _buildTextFormField(
                        initialValue: _footerEmail,
                        labelText: "Alt E-posta",
                        onSaved: (value) => _footerEmail = value ?? ""),
                    _buildTextFormField(
                        initialValue: _bankName,
                        labelText: "Banka Adı",
                        onSaved: (value) => _bankName = value ?? ""),
                    _buildTextFormField(
                        initialValue: _iban,
                        labelText: "IBAN",
                        onSaved: (value) => _iban = value ?? ""),
                    _buildTextFormField(
                        initialValue: _taxNumber,
                        labelText: "Vergi Numarası",
                        onSaved: (value) => _taxNumber = value ?? ""),
                    _buildTextFormField(
                        initialValue: _financeOffice,
                        labelText: "Vergi Dairesi / Finanzamt",
                        onSaved: (value) => _financeOffice = value ?? ""),
                    const SizedBox(height: AppConstants.padding),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:
                            const Icon(Icons.save, color: AppColors.background),
                        label: Text("Alt Bilgileri Kaydet",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.background)),
                        onPressed: _saveFooterSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellowAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.padding),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String? initialValue,
    required String labelText,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
    int? minLines, // minLines eklendi, opsiyonel
    int maxLines = 1, // maxLines varsayılan 1, minLines ile birlikte kullanılır
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padding),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.divider),
            borderRadius:
                BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.yellowAccent, width: 2),
            borderRadius:
                BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
          ),
        ),
        keyboardType: keyboardType,
        minLines: minLines, // minLines kullanıldı
        maxLines: maxLines, // maxLines kullanıldı
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  void _showColorPickerDialog(
      Color initialColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = initialColor;
        return AlertDialog(
          backgroundColor: AppColors.surface, // Dialog arka planı
          title: Text(
            'Renk Seçin',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              colorPickerWidth: 300.0,
              // pickerAreaHeightFraction: 0.7, // <<< BU SATIR KALDIRILDI
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              labelTypes: const [],
              pickerAreaBorderRadius: const BorderRadius.all(
                  Radius.circular(AppConstants.borderRadius)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(context).pop();
              },
              child: Text(
                'Tamam',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.yellowAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
