import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_model.dart';
import 'customer_provider.dart';
import 'customer_detail_page.dart' show CustomerDetailPage;
import 'customer_form.dart';
import 'work_entry_screen.dart';
import 'customer_material_form.dart'; // <-- Malzeme formunu import et

enum CustomerSortType { nameAZ, nameZA }

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchText = '';
  late TextEditingController _searchController;
  CustomerSortType _selectedSortType = CustomerSortType.nameAZ;
  Set<String> _favoriteCustomerIds = {};
  Map<String, String> _customerNotes = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filterCustomers(List<Customer> customers, String searchText) {
    if (searchText.trim().isEmpty) return customers;
    final terms = searchText.toLowerCase().split(RegExp(r"\s+"));
    return customers.where((customer) {
      final values = [
        customer.name,
        customer.email,
        customer.phone,
        customer.customerNumber ?? '',
      ].map((v) => v.toLowerCase()).join(" ");
      return terms.every((term) => values.contains(term));
    }).toList();
  }

  List<Customer> _sortCustomers(List<Customer> customers) {
    List<Customer> sorted = List<Customer>.from(customers);
    switch (_selectedSortType) {
      case CustomerSortType.nameAZ:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CustomerSortType.nameZA:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
    return sorted;
  }

  void _toggleFavorite(String customerId) {
    setState(() {
      if (_favoriteCustomerIds.contains(customerId)) {
        _favoriteCustomerIds.remove(customerId);
      } else {
        _favoriteCustomerIds.add(customerId);
      }
    });
  }

  void _editNote(BuildContext context, String customerId) async {
    final currentNote = _customerNotes[customerId] ?? '';
    final controller = TextEditingController(text: currentNote);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müşteri Notu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Bu müşteri için not girin...',
          ),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _customerNotes[customerId] = result;
      });
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Telefon açılamadı')));
    }
  }

  Future<void> _sendSMS(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SMS uygulaması açılamadı')));
    }
  }

  Future<void> _sendWhatsApp(String phone) async {
    String normalized = phone.replaceAll(RegExp(r'\D'), '');
    if (normalized.startsWith('0')) normalized = '90' + normalized.substring(1);
    final uri = Uri.parse('https://wa.me/$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WhatsApp açılamadı')));
    }
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google Maps açılamadı')));
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('E-posta açılamadı')));
    }
  }

  // Firestore'dan müşteri listesini çekmek için stream
  Stream<List<Customer>> _customersStream(BuildContext context) {
    return FirebaseFirestore.instance
        .collection('customers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Firestore'dan gelen id alanı boşsa veya yoksa doküman id'sini kullan!
            if (data['id'] == null || (data['id'] as String).isEmpty) {
              data['id'] = doc.id;
            }
            // Eksik alanlar için varsayılan değer ver
            data['name'] = data['name'] ?? '';
            data['email'] = data['email'] ?? '';
            data['phone'] = data['phone'] ?? '';
            data['address'] = data['address'] ?? '';
            data['customerNumber'] = data['customerNumber'] ?? '';
            return Customer.fromJson(data);
          }).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          PopupMenuButton<CustomerSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (sortType) {
              setState(() {
                _selectedSortType = sortType;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CustomerSortType.nameAZ,
                child: Text('İsme göre (A-Z)'),
              ),
              const PopupMenuItem(
                value: CustomerSortType.nameZA,
                child: Text('İsme göre (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _customersStream(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allCustomers = snapshot.data!;
          final filteredCustomers = _filterCustomers(allCustomers, _searchText);
          final sortedCustomers = _sortCustomers(filteredCustomers);

          final int totalCustomers = allCustomers.length;
          final int totalFavorites = _favoriteCustomerIds.length;
          final int filteredCount = filteredCustomers.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.grey.shade100,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.people,
                          label: "Toplam",
                          value: totalCustomers,
                          color: Colors.blue,
                        ),
                        _StatItem(
                          icon: Icons.star,
                          label: "Favori",
                          value: totalFavorites,
                          color: Colors.amber.shade700,
                        ),
                        _StatItem(
                          icon: Icons.filter_alt,
                          label: "Liste",
                          value: filteredCount,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ad, e-posta, telefon veya numara ile ara',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchText = '';
                                _searchController.clear();
                              });
                            },
                          ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchText = value);
                  },
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              Expanded(
                child: sortedCustomers.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı.'))
                    : ListView.builder(
                        itemCount: sortedCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = sortedCustomers[index];
                          final isFavorite = _favoriteCustomerIds.contains(
                            customer.id.toString(),
                          );
                          final note =
                              _customerNotes[customer.id.toString()] ?? '';

                          return Dismissible(
                            key: Key(customer.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) async {
                              // Firestore'dan sil
                              await FirebaseFirestore.instance
                                  .collection('customers')
                                  .doc(customer.id)
                                  .delete();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${customer.name} silindi'),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: ListTile(
                                title: Text(customer.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.email),
                                    if (note.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.note,
                                              size: 16,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                note,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                leading: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.star : Icons.star_border,
                                    color: isFavorite
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _toggleFavorite(customer.id.toString()),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (customer.phone.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.phone,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Ara',
                                        onPressed: () =>
                                            _callPhone(customer.phone),
                                      ),
                                    if (customer.phone.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.sms,
                                          color: Colors.orange,
                                        ),
                                        tooltip: 'SMS Gönder',
                                        onPressed: () =>
                                            _sendSMS(customer.phone),
                                      ),
                                    if (customer.phone.isNotEmpty)
                                      IconButton(
                                        icon: const FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'WhatsApp',
                                        onPressed: () =>
                                            _sendWhatsApp(customer.phone),
                                      ),
                                    if (customer.email.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.email,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'E-posta Gönder',
                                        onPressed: () =>
                                            _sendEmail(customer.email),
                                      ),
                                    if ((customer.address ?? '').isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Navigasyon (Google Maps)',
                                        onPressed: () =>
                                            _openMaps(customer.address!),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_note),
                                      tooltip: 'Not Ekle/Düzenle',
                                      onPressed: () => _editNote(
                                        context,
                                        customer.id.toString(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Düzenle',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CustomerFormScreen(
                                                  initialCustomer: customer,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.work_outline),
                                      tooltip: 'İşçilik / Çalışma Kalemleri',
                                      onPressed: () {
                                        if (customer.id.isEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Geçersiz Müşteri',
                                              ),
                                              content: const Text(
                                                'Geçersiz müşteri! Lütfen önce müşteri oluşturun.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: const Text('Tamam'),
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WorkEntryScreen(
                                                  customer: customer,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    // --- MALZEME İKONU EKLENDİ ---
                                    IconButton(
                                      icon: const Icon(Icons.inventory_2),
                                      tooltip: 'Malzemeleri Gör',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                title: Text(
                                                  "${customer.name} Malzemeler",
                                                ),
                                              ),
                                              body: CustomerMaterialForm(
                                                customerId: customer.id,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // --- MALZEME İKONU BİTİŞ ---
                                  ],
                                ),
                                onTap: () {
                                  // Null veya boş id/name için kontrol ekle
                                  if (customer.id.isEmpty ||
                                      customer.name.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Geçersiz Müşteri'),
                                        content: const Text(
                                          'Geçersiz müşteri! Lütfen önce müşteri oluşturun.',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Tamam'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailPage(
                                        customer: customer,
                                        allTasks:
                                            const [], // Gerçek task verisi eklenmeli
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
