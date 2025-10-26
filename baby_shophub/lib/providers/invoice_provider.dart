import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/business_model.dart';
import '../services/invoice_repository.dart';
import '../services/pdf_service.dart';
import '../services/email_service.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceRepository _invoiceRepository;
  final PDFService _pdfService;
  final EmailService _emailService;

  InvoiceProvider()
    : _invoiceRepository = InvoiceRepository(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      _pdfService = PDFService(),
      _emailService = EmailService();

  List<Invoice> _invoices = [];
  List<Client> _clients = [];
  List<Product> _products = [];
  List<Business> _businesses = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Invoice> get invoices => _invoices;
  List<Client> get clients => _clients;
  List<Product> get products => _products;
  List<Business> get businesses => _businesses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered invoices
  List<Invoice> get draftInvoices =>
      _invoices.where((i) => i.status == 'draft').toList();
  List<Invoice> get sentInvoices =>
      _invoices.where((i) => i.status == 'sent').toList();
  List<Invoice> get paidInvoices =>
      _invoices.where((i) => i.status == 'paid').toList();
  List<Invoice> get overdueInvoices =>
      _invoices.where((i) => i.status == 'overdue').toList();

  // Dashboard stats
  Map<String, dynamic> get dashboardStats {
    double totalRevenue = 0;
    double pendingAmount = 0;
    double paidAmount = 0;
    double overdueAmount = 0;

    for (var invoice in _invoices) {
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
      'totalInvoices': _invoices.length,
    };
  }

  // Load all data
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load invoices
      final invoicesStream = _invoiceRepository.getAllInvoices();
      invoicesStream.listen((invoices) {
        _invoices = invoices;
        notifyListeners();
      });

      // TODO: Load clients, products, and businesses
      // For now, we'll initialize with empty lists
      _clients = [];
      _products = [];
      _businesses = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create invoice
  Future<String?> createInvoice(Invoice invoice) async {
    try {
      _isLoading = true;
      notifyListeners();

      final invoiceId = await _invoiceRepository.createInvoice(invoice);
      await loadAllData(); // Refresh data

      return invoiceId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update invoice
  Future<bool> updateInvoice(String invoiceId, Invoice invoice) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _invoiceRepository.updateInvoice(invoiceId, invoice);
      await loadAllData(); // Refresh data

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _invoiceRepository.deleteInvoice(invoiceId);
      await loadAllData(); // Refresh data

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate PDF
  Future<Uint8List?> generateInvoicePDF(
    Invoice invoice,
    Business business,
  ) async {
    try {
      return await PDFService.generateInvoicePDF(invoice, business);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Send invoice email
  Future<bool> sendInvoiceEmail({
    required String invoiceId,
    required String clientEmail,
    required String pdfUrl,
    required String invoiceNumber,
  }) async {
    try {
      await _emailService.sendInvoiceEmail(
        invoiceId: invoiceId,
        clientEmail: clientEmail,
        pdfUrl: pdfUrl,
        invoiceNumber: invoiceNumber,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Mark invoice as paid
  Future<bool> markInvoiceAsPaid(
    String invoiceId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      await _invoiceRepository.markInvoiceAsPaid(
        invoiceId,
        amount,
        paymentMethod,
      );
      await loadAllData(); // Refresh data
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Update invoice status
  Future<bool> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _invoiceRepository.updateInvoiceStatus(invoiceId, status);
      await loadAllData(); // Refresh data
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Get invoice by ID
  Invoice? getInvoiceById(String id) {
    return _invoices.firstWhere((invoice) => invoice.id == id);
  }

  // Get client by ID
  Client? getClientById(String id) {
    return _clients.firstWhere((client) => client.id == id);
  }

  // Get product by ID
  Product? getProductById(String id) {
    return _products.firstWhere((product) => product.id == id);
  }

  // Get business by ID
  Business? getBusinessById(String id) {
    return _businesses.firstWhere((business) => business.id == id);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
