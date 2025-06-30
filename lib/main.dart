// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

import 'dart:io' as io show File;

import 'firebase_options.dart';
import 'utils/constants.dart';
import 'modules/customers/customer_list.dart';
import 'modules/customers/customer_model.dart';
import 'modules/customers/customer_provider.dart';
import 'modules/customers/customer_material_model.dart';
import 'modules/proposals/proposal_list.dart';
import 'modules/tasks/task_list.dart';
import 'modules/invoices/invoice_list.dart';
import 'modules/reports/analytics.dart';
import 'modules/employees/employee_list.dart';
import 'modules/integration/integration_service.dart';
import 'modules/security/security_service.dart';
import 'modules/feedback/feedback_list.dart';
import 'modules/offline/offline_service.dart';
import 'modules/settings/settings_home_page.dart';
import 'modules/settings/company_settings_model.dart';
import 'modules/settings/theme_notifier.dart';
import 'modules/settings/company_customization_page.dart';
import 'modules/settings/admin_settings.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

const localizedValues = {
  'en': {
    'customers': 'Customers',
    'proposals': 'Proposals',
    'tasks': 'Tasks',
    'invoices': 'Invoices',
    'reports': 'Reports',
    'employees': 'Employees',
    'integration': 'Integration',
    'security': 'Security',
    'feedback': 'Feedback',
    'offline': 'Offline',
    'settings': 'Settings',
    'company_customization': 'Company Customization',
    'admin_settings': 'Admin Settings',
    'firebase_error':
        'Could not initialize Firebase. Please check your internet connection and Firebase settings.',
    'loading_customers': 'Loading customers...',
    'no_customers_available': 'No customers available.',
    'loading_settings': 'Loading settings...',
  },
  'tr': {
    'customers': 'Müşteriler',
    'proposals': 'Teklifler',
    'tasks': 'Görevler',
    'invoices': 'Faturalar',
    'reports': 'Raporlar',
    'employees': 'Çalışanlar',
    'integration': 'Entegrasyon',
    'security': 'Güvenlik',
    'feedback': 'Geri Bildirim',
    'offline': 'Offline',
    'settings': 'Ayarlar',
    'company_customization': 'Şirket Özelleştirmeleri',
    'admin_settings': 'Admin Ayarları',
    'firebase_error':
        'Firebase başlatılamadı. Lütfen internet bağlantınızı ve Firebase ayarlarınızı kontrol edin.',
    'loading_customers': 'Müşteriler yükleniyor...',
    'no_customers_available': 'Müşteri bulunamadı.',
    'loading_settings': 'Ayarlar yükleniyor...',
  },
};

String translate(BuildContext context, String key) {
  Locale locale = Localizations.localeOf(context);
  return localizedValues[locale.languageCode]?[key] ?? key;
}

late FirebaseFirestore db;
late FirebaseAuth auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    db = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await _signInAnonymously();
    }
    firebaseInitialized = true;
  } catch (e) {
    print("Firebase initialization error: $e");
    firebaseInitialized = false;
  }

  runApp(
    firebaseInitialized
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CustomerProvider(db)),
              ChangeNotifierProvider(
                create: (_) => ThemeNotifier(ThemeData.dark()),
              ),
            ],
            child: const MyApp(),
          )
        : const ErrorApp(),
  );
}

Future<void> _signInAnonymously() async {
  try {
    if (auth.currentUser == null) {
      UserCredential userCredential = await auth.signInAnonymously();
      print("Signed in anonymously with UID: ${userCredential.user?.uid}");
    }
  } catch (e) {
    print("Anonymous sign-in failed: $e");
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Text(
            translate(context, 'firebase_error'),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CompanySettings _companySettings;
  bool _isSettingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanySettingsAndInitTheme();
  }

  Future<void> _loadCompanySettingsAndInitTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString('company_settings');

    CompanySettings loadedSettings;
    if (settingsJson != null) {
      try {
        loadedSettings = CompanySettings.fromJson(json.decode(settingsJson));
        print("Ayarlar SharedPreferences'tan başarıyla yüklendi.");
      } catch (e) {
        print("SharedPreferences'tan ayarlar yüklenirken hata oluştu: $e");
        loadedSettings = CompanySettings.defaultSettings();
      }
    } else {
      loadedSettings = CompanySettings.defaultSettings();
      print("Kayıtlı ayar bulunamadı, varsayılan ayarlar kullanılıyor.");
    }

    if (mounted) {
      setState(() {
        _companySettings = loadedSettings;
        _isSettingsLoading = false;
        final themeNotifier = Provider.of<ThemeNotifier>(
          context,
          listen: false,
        );
        themeNotifier.updateThemeData(
          _buildThemeData(
            _companySettings.themeColor ?? AppColors.yellowAccent,
          ),
        );
      });
    }
  }

  ThemeData _buildThemeData(Color baseColor) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: baseColor,
      colorScheme: ColorScheme.dark(
        primary: baseColor,
        secondary: baseColor,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.white,
        onError: AppColors.white,
        onBackground: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: baseColor,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: baseColor),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseColor, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: baseColor),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: baseColor,
        unselectedItemColor: Colors.white54,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.background),
      dividerColor: baseColor,
      primarySwatch: MaterialColor(baseColor.value, <int, Color>{
        50: baseColor.withOpacity(0.1),
        100: baseColor.withOpacity(0.2),
        200: baseColor.withOpacity(0.3),
        300: baseColor.withOpacity(0.4),
        400: baseColor.withOpacity(0.5),
        500: baseColor.withOpacity(0.6),
        600: baseColor.withOpacity(0.7),
        700: baseColor.withOpacity(0.8),
        800: baseColor.withOpacity(0.9),
        900: baseColor.withOpacity(1.0),
      }),
    );
  }

  Future<void> _updateCompanySettings(CompanySettings newSettings) async {
    if (mounted) {
      setState(() {
        _companySettings = newSettings;
        final themeNotifier = Provider.of<ThemeNotifier>(
          context,
          listen: false,
        );
        themeNotifier.updateThemeData(
          _buildThemeData(newSettings.themeColor ?? AppColors.yellowAccent),
        );
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'company_settings',
      json.encode(newSettings.toJson()),
    );
    print("Şirket ayarları SharedPreferences'a kaydedildi.");
  }

  @override
  Widget build(BuildContext context) {
    if (_isSettingsLoading) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  translate(context, 'loading_settings'),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final customerProvider = Provider.of<CustomerProvider>(context);
    final List<Customer> allCustomers = customerProvider.customers;

    if (allCustomers.isEmpty && customerProvider.isLoading) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.yellowAccent),
                const SizedBox(height: 16),
                Text(
                  translate(context, 'loading_customers'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (allCustomers.isEmpty && !customerProvider.isLoading) {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Text(
              translate(context, 'no_customers_available'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final Customer selectedCustomerForInvoiceModule =
        allCustomers.isNotEmpty ? allCustomers.first : Customer.empty();

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) => MaterialApp(
        title: 'MyService App',
        theme: themeNotifier.themeData,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: MainScreen(
          companySettings: _companySettings,
          onCompanySettingsChanged: _updateCompanySettings,
          currentCustomer: selectedCustomerForInvoiceModule,
          allCustomers: allCustomers,
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/customers': (ctx) => const CustomerListScreen(),
          '/proposals': (ctx) => const ProposalList(),
          '/tasks': (ctx) => const TaskList(),
          '/reports': (ctx) => const AnalyticsPage(),
          '/employees': (ctx) => const EmployeeList(),
          '/integration': (ctx) => const IntegrationService(),
          '/security': (ctx) => const SecurityService(),
          '/feedback': (ctx) => const FeedbackList(),
          '/offline': (ctx) => const OfflineService(),
          '/settings': (ctx) => SettingsHomePage(
                companySettings: _companySettings,
                onCompanySettingsChanged: _updateCompanySettings,
              ),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final CompanySettings companySettings;
  final void Function(CompanySettings) onCompanySettingsChanged;
  final Customer currentCustomer;
  final List<Customer> allCustomers;

  const MainScreen({
    super.key,
    required this.companySettings,
    required this.onCompanySettingsChanged,
    required this.currentCustomer,
    required this.allCustomers,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const CustomerListScreen(),
        const ProposalList(),
        const TaskList(),
        InvoiceList(
          customer: widget.currentCustomer,
          companySettings: widget.companySettings,
          allCustomers: widget.allCustomers,
        ),
        const AnalyticsPage(),
        const EmployeeList(),
        const IntegrationService(),
        const SecurityService(),
        const FeedbackList(),
        const OfflineService(),
        SettingsHomePage(
          companySettings: widget.companySettings,
          onCompanySettingsChanged: widget.onCompanySettingsChanged,
        ),
      ];

  final List<String> _titleKeys = [
    "customers",
    "proposals",
    "tasks",
    "invoices",
    "reports",
    "employees",
    "integration",
    "security",
    "feedback",
    "offline",
    "settings",
  ];

  final List<IconData> _icons = [
    Icons.people,
    Icons.lightbulb,
    Icons.check_circle,
    Icons.receipt_long,
    Icons.bar_chart,
    Icons.group,
    Icons.link,
    Icons.security,
    Icons.feedback,
    Icons.offline_bolt,
    Icons.settings,
  ];

  List<Widget> _drawerItems() {
    return List.generate(_titleKeys.length, (i) {
      if (_titleKeys[i] == "settings") {
        return ExpansionTile(
          leading: Icon(_icons[i], color: Theme.of(context).iconTheme.color),
          title: Text(
            translate(context, _titleKeys[i]),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          initiallyExpanded: false,
          children: [
            ListTile(
              leading: Icon(
                Icons.tune,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                translate(context, 'company_customization'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await Navigator.push<CompanySettings>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyCustomizationPage(
                      companySettings: widget.companySettings,
                      onCompanySettingsChanged: widget.onCompanySettingsChanged,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                translate(context, 'admin_settings'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
                );
              },
            ),
          ],
        );
      }
      return ListTile(
        leading: Icon(_icons[i], color: Theme.of(context).iconTheme.color),
        title: Text(
          translate(context, _titleKeys[i]),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        selected: _currentIndex == i,
        onTap: () {
          setState(() => _currentIndex = i);
          Navigator.of(context).pop();
        },
      );
    });
  }

  static const int maxBottomTabs = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translate(context, _titleKeys[_currentIndex]),
          style: AppTextStyles.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color:
                    widget.companySettings.themeColor ?? AppColors.yellowAccent,
              ),
              child: Row(
                children: [
                  (widget.companySettings.logoPath != null &&
                          widget.companySettings.logoPath!.isNotEmpty)
                      ? kIsWeb
                          ? Image.network(
                              widget.companySettings.logoPath!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.business,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            )
                          : (io.File(widget.companySettings.logoPath!)
                                  .existsSync()
                              ? Image.file(
                                  io.File(widget.companySettings.logoPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.business,
                                  size: 48,
                                  color: AppColors.primary,
                                ))
                      : const Icon(
                          Icons.business,
                          size: 48,
                          color: AppColors.primary,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.companySettings.companyName,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.companySettings.companyDescription != null &&
                            widget
                                .companySettings.companyDescription!.isNotEmpty)
                          Text(
                            widget.companySettings.companyDescription!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ..._drawerItems(),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < maxBottomTabs ? _currentIndex : 0,
        onTap: (i) {
          setState(() => _currentIndex = i);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor,
        items: List.generate(
          maxBottomTabs,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: translate(context, _titleKeys[i]),
          ),
        ),
      ),
    );
  }
}
