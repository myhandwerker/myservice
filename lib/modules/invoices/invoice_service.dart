// lib/modules/invoices/invoice_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_model.dart';

class InvoiceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _invoiceCollection = _db.collection(
    'invoices',
  );

  static Future<void> addInvoice(Invoice invoice) async {
    try {
      await _invoiceCollection.add(invoice.toFirestore());
    } catch (e) {
      print("Fatura eklenirken hata oluştu: $e");
      throw Exception("Fatura eklenirken bir hata oluştu: $e");
    }
  }

  static Future<void> updateInvoice(String invoiceId, Invoice invoice) async {
    try {
      await _invoiceCollection.doc(invoiceId).set(invoice.toFirestore());
    } catch (e) {
      print("Fatura güncellenirken hata oluştu: $e");
      throw Exception("Fatura güncellenirken bir hata oluştu: $e");
    }
  }

  static Future<List<Invoice>> getInvoices({String? customerId}) async {
    try {
      Query query = _invoiceCollection;
      if (customerId != null && customerId.isNotEmpty) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      final snap = await query.get();
      return snap.docs
          .map(
            (doc) => Invoice.fromFirestore(doc as DocumentSnapshot),
          )
          .toList();
    } catch (e) {
      print("Faturalar çekilirken hata oluştu: $e");
      throw Exception("Faturalar yüklenirken bir hata oluştu: $e");
    }
  }

  static Stream<List<Invoice>> streamInvoices({String? customerId}) {
    Query query = _invoiceCollection;
    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    return query.snapshots().handleError((error) {
      print("Faturalar stream edilirken hata oluştu: $error");
      throw error;
    }).map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => Invoice.fromFirestore(doc as DocumentSnapshot),
          )
          .toList(),
    );
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _invoiceCollection.doc(invoiceId).delete();
    } catch (e) {
      print("Fatura silinirken hata oluştu: $e");
      throw Exception("Fatura silinirken bir hata oluştu: $e");
    }
  }
}
