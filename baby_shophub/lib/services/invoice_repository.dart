import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/business_model.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  InvoiceRepository(this._userId);

  Future<String> createInvoice(Invoice invoice) async {
    try {
      // Generate invoice number
      final businessDoc = await _firestore
          .collection('businesses')
          .doc(_userId)
          .collection('profiles')
          .doc(invoice.businessProfileId)
          .get();

      if (!businessDoc.exists) {
        throw Exception('Business profile not found');
      }

      final businessData = businessDoc.data()!;
      final invoiceSettings = InvoiceSettings.fromMap(
        businessData['invoiceSettings'] ?? {},
      );
      int nextNumber = invoiceSettings.currentNumber + 1;
      String invoiceNumber =
          '${invoiceSettings.prefix}${DateTime.now().year}-${nextNumber.toString().padLeft(4, '0')}';

      // Create invoice document
      final docRef = await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .add({
            ...invoice.toMap(),
            'invoiceNumber': invoiceNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update invoice counter
      await _firestore
          .collection('businesses')
          .doc(_userId)
          .collection('profiles')
          .doc(invoice.businessProfileId)
          .update({'invoiceSettings.currentNumber': nextNumber});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<void> updateInvoice(String invoiceId, Invoice invoice) async {
    try {
      await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .doc(invoiceId)
          .update({
            ...invoice.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .doc(invoiceId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  Future<Invoice> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .doc(invoiceId)
          .get();

      if (!doc.exists) {
        throw Exception('Invoice not found');
      }

      return Invoice.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  Stream<List<Invoice>> getInvoicesByStatus(String status) {
    return _firestore
        .collection('invoices')
        .doc(_userId)
        .collection('list')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Invoice.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Invoice>> getAllInvoices() {
    return _firestore
        .collection('invoices')
        .doc(_userId)
        .collection('list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Invoice.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final invoices = await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .get();

      double totalRevenue = 0;
      double pendingAmount = 0;
      double paidAmount = 0;
      double overdueAmount = 0;
      int totalInvoices = 0;

      for (var doc in invoices.docs) {
        final invoice = Invoice.fromMap(doc.data(), doc.id);
        totalInvoices++;
        totalRevenue += invoice.total;

        if (invoice.status == 'paid') {
          paidAmount += invoice.total;
        } else if (invoice.status == 'overdue') {
          overdueAmount += invoice.balanceDue;
          pendingAmount += invoice.balanceDue;
        } else if (invoice.status == 'sent' || invoice.status == 'viewed') {
          pendingAmount += invoice.balanceDue;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'paidAmount': paidAmount,
        'overdueAmount': overdueAmount,
        'totalInvoices': totalInvoices,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<void> markInvoiceAsPaid(
    String invoiceId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .doc(invoiceId)
          .update({
            'status': 'paid',
            'paidAmount': amount,
            'balanceDue': 0,
            'paidDate': FieldValue.serverTimestamp(),
            'paymentMethod': paymentMethod,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark invoice as paid: $e');
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .doc(invoiceId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update invoice status: $e');
    }
  }
}
