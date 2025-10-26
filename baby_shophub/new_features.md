# Complete Invoice System Integration Guide
### Inspired by Billin - Fast Invoice Maker
### For Flutter + Firebase Production Apps

---

## 📋 Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [Complete Feature Breakdown](#complete-feature-breakdown)
3. [Database Schema Design](#database-schema-design)
4. [Screen-by-Screen Implementation](#screen-by-screen-implementation)
5. [Core Features Code Examples](#core-features-code-examples)
6. [Advanced Features](#advanced-features)
7. [Security & Performance](#security--performance)
8. [Deployment Checklist](#deployment-checklist)
9. [Monetization Strategy](#monetization-strategy)

---

## 🏗️ System Architecture Overview

### Tech Stack
```yaml
Frontend: Flutter 3.x
State Management: Provider / Riverpod / Bloc (choose one)
Backend: Firebase
  - Firestore: Database
  - Storage: PDF & image storage
  - Auth: User authentication
  - Functions: Server-side operations
  - Analytics: User behavior tracking
PDF Generation: pdf package (flutter)
Email Service: Firebase Functions + SendGrid/Mailgun
Payment: Stripe/Razorpay (for premium features)
Local Storage: Hive/SharedPreferences (offline mode)
```

### Architecture Pattern
```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── services/
├── data/
│   ├── models/
│   ├── repositories/
│   └── providers/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── view_models/
├── features/
│   ├── invoice/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── client/
│   ├── product/
│   └── reports/
└── main.dart
```

---

## 🎯 Complete Feature Breakdown

### Core Features (MVP - Must Have)

#### 1. Invoice Management
- ✅ Create invoices with line items
- ✅ Edit/duplicate existing invoices
- ✅ Delete invoices (with confirmation)
- ✅ Preview before sending
- ✅ Save as draft
- ✅ Generate PDF
- ✅ Send via email
- ✅ Track status (Draft, Sent, Paid, Overdue, Cancelled)

#### 2. Client Management
- ✅ Add/edit/delete clients
- ✅ Store client details (name, email, phone, address, tax ID)
- ✅ View client history (all invoices)
- ✅ Quick select from client list when creating invoice
- ✅ Import contacts from phone

#### 3. Product/Service Management
- ✅ Add products/services with prices
- ✅ Set default tax rates
- ✅ Quick add to invoice
- ✅ Category organization
- ✅ Stock tracking (optional)

#### 4. Business Profile
- ✅ Company name, logo, address
- ✅ Tax registration number
- ✅ Bank account details
- ✅ Payment terms & notes
- ✅ Invoice numbering format

### Advanced Features (Premium)

#### 5. Smart Features
- 📊 Dashboard with analytics
- 📈 Revenue reports & charts
- 💰 Payment reminders (automated)
- 🔔 Overdue notifications
- 📱 Multi-currency support
- 🌍 Multi-language invoices
- 📦 Recurring invoices
- 💳 Payment gateway integration
- 📤 Bulk invoice sending
- 📥 Expense tracking

#### 6. Customization
- 🎨 Invoice template themes
- 🖼️ Custom branding
- 📝 Custom fields
- 💱 Tax calculations (GST, VAT, Sales Tax)
- 🧾 Estimates/Quotations
- 📋 Purchase orders

#### 7. Professional Tools
- ☁️ Cloud backup & sync
- 👥 Multi-user access (team features)
- 🔒 Password protection for PDFs
- 📧 Email templates
- 📲 WhatsApp sharing
- 🖨️ Thermal printer support
- 📊 Export to Excel/CSV

---

## 🗄️ Database Schema Design

### Firestore Collections Structure

```javascript
// Collection: users
users/{userId}
{
  email: string,
  displayName: string,
  photoURL: string,
  createdAt: timestamp,
  subscription: {
    plan: "free" | "premium" | "business",
    validUntil: timestamp,
    invoiceLimit: number
  },
  settings: {
    currency: string,
    timezone: string,
    language: string,
    defaultTaxRate: number
  }
}

// Collection: businesses (user's business profiles)
businesses/{userId}/profiles/{profileId}
{
  businessName: string,
  logo: string,
  email: string,
  phone: string,
  website: string,
  address: {
    street: string,
    city: string,
    state: string,
    zipCode: string,
    country: string
  },
  taxId: string,
  bankDetails: {
    accountName: string,
    accountNumber: string,
    bankName: string,
    swiftCode: string
  },
  invoiceSettings: {
    prefix: string,
    startNumber: number,
    currentNumber: number,
    numberFormat: string
  },
  paymentTerms: string,
  notes: string,
  isDefault: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: clients
clients/{userId}/list/{clientId}
{
  name: string,
  email: string,
  phone: string,
  company: string,
  taxId: string,
  address: {
    street: string,
    city: string,
    state: string,
    zipCode: string,
    country: string
  },
  notes: string,
  tags: array<string>,
  totalInvoiced: number,
  totalPaid: number,
  outstandingAmount: number,
  invoiceCount: number,
  lastInvoiceDate: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: products
products/{userId}/list/{productId}
{
  name: string,
  description: string,
  price: number,
  unit: string,
  taxRate: number,
  category: string,
  sku: string,
  stockQuantity: number,
  isService: boolean,
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: invoices
invoices/{userId}/list/{invoiceId}
{
  invoiceNumber: string,
  businessProfileId: string,
  clientId: string,
  clientDetails: {
    name: string,
    email: string,
    phone: string,
    address: object
  },
  items: [
    {
      productId: string,
      name: string,
      description: string,
      quantity: number,
      unit: string,
      rate: number,
      taxRate: number,
      taxAmount: number,
      amount: number,
      total: number
    }
  ],
  subtotal: number,
  totalTax: number,
  discount: {
    type: "percentage" | "fixed",
    value: number,
    amount: number
  },
  shippingCost: number,
  total: number,
  currency: string,
  status: "draft" | "sent" | "viewed" | "paid" | "overdue" | "cancelled",
  dueDate: timestamp,
  issueDate: timestamp,
  paidDate: timestamp,
  paidAmount: number,
  balanceDue: number,
  paymentMethod: string,
  notes: string,
  terms: string,
  attachments: array<string>,
  pdfUrl: string,
  emailSent: boolean,
  emailSentAt: timestamp,
  viewedAt: timestamp,
  remindersSent: number,
  lastReminderAt: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: payments
payments/{userId}/list/{paymentId}
{
  invoiceId: string,
  clientId: string,
  amount: number,
  paymentMethod: string,
  referenceNumber: string,
  notes: string,
  paymentDate: timestamp,
  createdAt: timestamp
}

// Collection: expenses (Premium feature)
expenses/{userId}/list/{expenseId}
{
  category: string,
  amount: number,
  description: string,
  vendor: string,
  receiptUrl: string,
  date: timestamp,
  createdAt: timestamp
}

// Collection: templates
templates/{userId}/list/{templateId}
{
  name: string,
  htmlContent: string,
  cssStyles: string,
  isDefault: boolean,
  preview: string,
  createdAt: timestamp
}
```

---

## 📱 Screen-by-Screen Implementation

### 1. Dashboard Screen (Home)
**Purpose:** Overview of business performance and quick actions

**Key Sections:**
- Quick Stats Cards (Total Revenue, Pending, Paid, Overdue)
- Quick Actions (Create Invoice, Add Client, Add Product, Reports)
- Recent Invoices (last 5 invoices)
- Overdue Alerts (red banner if invoices overdue)
- Revenue Chart (monthly/weekly trends)

**Widgets Needed:**
- StatCard: Displays metric with icon and trend
- QuickActionButton: Circular icon button with label
- InvoiceListItem: Invoice card with status badge
- OverdueAlertBanner: Red alert banner
- RevenueChart: Line/bar chart component

### 2. Invoice List Screen
**Purpose:** View all invoices with filtering and search

**Key Features:**
- Filter by status (All, Draft, Sent, Paid, Overdue)
- Search by invoice number or client name
- Sort by date, amount, or status
- Bulk actions (delete, send reminder)
- Swipe actions (edit, delete, download)

**Widgets Needed:**
- FilterChip: Status filter with count badge
- InvoiceCard: Complete invoice preview
- StatusBadge: Colored badge for invoice status
- ActionIconButton: Quick action buttons
- EmptyState: When no invoices exist

### 3. Create/Edit Invoice Screen
**Purpose:** Create new invoice or edit existing one

**Key Sections:**
- Invoice Number (auto-generated from prefix + sequence)
- Client Selection (dropdown with search)
- Issue Date & Due Date (date pickers)
- Line Items (add/edit/remove items)
- Totals Calculation (subtotal, tax, discount, shipping)
- Notes & Terms (text fields)
- Save as Draft or Create

**Widgets Needed:**
- ClientSelector: Modal/dialog for client selection
- LineItemCard: Editable item with inline calculation
- LineItemModal: Full edit form for item
- TotalsSection: Real-time total calculation
- ProductSelector: Quick product selection

### 4. Invoice Detail Screen
**Purpose:** View complete invoice details and perform actions

**Key Sections:**
- Invoice Header (number, status, dates)
- Client Information (full address, contact)
- Line Items List (with taxes)
- Totals Section (all calculations)
- Payment Status (paid/pending amount)
- Action Buttons (Edit, Delete, Share, Download, Email, Mark as Paid)
- Email History (if sent)
- Payment History (all recorded payments)

**Widgets Needed:**
- InvoicePreview: Professional invoice display
- PaymentRecordCard: Payment entry card
- ActionBottomSheet: Quick actions menu

### 5. Client Management Screen
**Purpose:** Manage all clients

**Key Sections:**
- Client List with search
- Client Stats (total invoiced, outstanding, invoice count)
- Add Client Button
- Client Card (name, company, email, phone)
- Swipe Actions (edit, delete, view history)

**Widgets Needed:**
- ClientCard: Client information card
- ClientForm: Add/edit client form
- ClientStats: Summary widget

### 6. Product Management Screen
**Purpose:** Manage products/services

**Key Sections:**
- Product List with categories
- Search & Filter by category
- Add Product Button
- Product Card (name, price, category, status)
- Bulk actions (enable/disable, delete)

**Widgets Needed:**
- ProductCard: Product information card
- ProductForm: Add/edit product form
- CategoryFilter: Filter by category

### 7. Settings Screen
**Purpose:** Configure business profile and app settings

**Key Sections:**
- Business Profile (company info, logo, address)
- Invoice Settings (prefix, number format, terms)
- Tax Settings (default tax rate, types)
- Payment Settings (payment methods, gateway)
- App Settings (currency, language, timezone)
- Account Settings (email, password, subscription)

---

## 🔧 Core Features Code Examples

### PDF Generation Service

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFService {
  static Future<Uint8List> generateInvoicePDF(Invoice invoice, Business business) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and business info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        business.businessName,
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(business.address.street),
                      pw.Text('${business.address.city}, ${business.address.state}'),
                      pw.Text(business.email),
                      pw.Text(business.phone),
                    ],
                  ),
                  if (business.logo != null)
                    pw.Image(
                      pw.NetworkImage(business.logo!),
                      width: 100,
                      height: 100,
                    ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Invoice details
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                      pw.Text('Issue Date: ${_formatDate(invoice.issueDate)}'),
                      pw.Text('Due Date: ${_formatDate(invoice.dueDate)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Bill to section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(invoice.clientDetails.name),
                  pw.Text(invoice.clientDetails.email),
                  pw.Text(invoice.clientDetails.phone),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Tax', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.name),
                            pw.Text(item.description, style: pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                        pw.Text('${item.quantity}'),
                        pw.Text('\$${item.rate.toStringAsFixed(2)}'),
                        pw.Text('${item.taxRate}%'),
                        pw.Text('\$${item.total.toStringAsFixed(2)}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:'),
                        pw.Text('\$${invoice.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tax:'),
                        pw.Text('\$${invoice.totalTax.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (invoice.discount.amount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Discount:'),
                          pw.Text('-\$${invoice.discount.amount.toStringAsFixed(2)}'),
                        ],
                      ),
                    if (invoice.shippingCost > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Shipping:'),
                          pw.Text('\$${invoice.shippingCost.toStringAsFixed(2)}'),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('\$${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Notes and terms
              if (invoice.notes.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.notes),
                  ],
                ),
              pw.SizedBox(height: 10),
              if (invoice.terms.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.terms),
                  ],
                ),
              pw.SizedBox(height: 20),

              // Bank details
              if (business.bankDetails != null)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Bank: ${business.bankDetails!.bankName}'),
                    pw.Text('Account: ${business.bankDetails!.accountNumber}'),
                    pw.Text('SWIFT: ${business.bankDetails!.swiftCode}'),
                  ],
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

### Email Service

```dart
import 'cloud_functions/cloud_functions.dart';

class EmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> sendInvoiceEmail({
    required String invoiceId,
    required String clientEmail,
    required String pdfUrl,
    required String invoiceNumber,
  }) async {
    try {
      await _functions.httpsCallable('sendInvoiceEmail').call({
        'invoiceId': invoiceId,
        'clientEmail': clientEmail,
        'pdfUrl': pdfUrl,
        'invoiceNumber': invoiceNumber,
        'subject': 'Invoice $invoiceNumber',
        'message': 'Please find attached your invoice.',
      });

      // Update invoice status
      await FirebaseFirestore.instance.collection('invoices').doc(invoiceId).update({
        'emailSent': true,
        'emailSentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  Future<void> sendPaymentReminder({
    required String invoiceId,
    required String clientEmail,
    required String invoiceNumber,
    required double amountDue,
  }) async {
    try {
      await _functions.httpsCallable('sendPaymentReminder').call({
        'invoiceId': invoiceId,
        'clientEmail': clientEmail,
        'invoiceNumber': invoiceNumber,
        'amountDue': amountDue,
      });

      // Update reminder count
      await FirebaseFirestore.instance.collection('invoices').doc(invoiceId).update({
        'remindersSent': FieldValue.increment(1),
        'lastReminderAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send reminder: $e');
    }
  }
}
```

### Invoice Repository

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  InvoiceRepository(this._userId);

  Future<String> createInvoice(Invoice invoice) async {
    try {
      // Generate invoice number
      final numberDoc = await _firestore
          .collection('businesses')
          .doc(_userId)
          .collection('profiles')
          .doc(invoice.businessProfileId)
          .get();

      int nextNumber = (numberDoc['invoiceSettings']['currentNumber'] ?? 0) + 1;
      String prefix = numberDoc['invoiceSettings']['prefix'] ?? 'INV-';
      String invoiceNumber = '$prefix${DateTime.now().year}-${nextNumber.toString().padLeft(4, '0')}';

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
          .update({
        'invoiceSettings.currentNumber': nextNumber,
      });

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
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Invoice>> getAllInvoices() {
    return _firestore
        .collection('invoices')
        .doc(_userId)
        .collection('list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
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
}
```

---

## 🔐 Security & Performance

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /invoices/{userId}/list/{invoiceId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId && 
                       request.resource.data.keys().hasAll(['invoiceNumber', 'total']);
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }

    match /clients/{userId}/list/{clientId} {
      allow read, create, update, delete: if request.auth.uid == userId;
    }

    match /products/{userId}/list/{productId} {
      allow read, create, update, delete: if request.auth.uid == userId;
    }

    match /businesses/{userId}/profiles/{profileId} {
      allow read, create, update, delete: if request.auth.uid == userId;
    }
  }
}
```

### Performance Optimization

- Use pagination for invoice lists (limit: 20)
- Implement pagination with cursor-based navigation
- Cache frequently accessed data locally (Hive)
- Use indexes for common queries
- Implement debouncing for search
- Load images with thumbnails before full resolution
- Use lazy loading for invoice details

### Caching Strategy

```dart
class CacheService {
  final Box<dynamic> _box;

  Future<void> cacheInvoice(Invoice invoice) async {
    await _box.put('invoice_${invoice.id}', invoice);
  }

  Invoice? getCachedInvoice(String id) {
    return _box.get('invoice_$id');
  }

  Future<void> clearCache() async {
    await _box.clear();
  }
}
```

---

## 🚀 Deployment Checklist

### Pre-Launch
- [ ] Complete testing on iOS and Android
- [ ] Implement offline mode with Hive
- [ ] Set up Firebase Hosting for web version
- [ ] Configure email service (SendGrid/Mailgun)
- [ ] Set up payment gateway (Stripe/Razorpay)
- [ ] Implement analytics (Firebase Analytics)
- [ ] Test PDF generation on all devices
- [ ] Validate Firestore security rules
- [ ] Test email delivery and templates
- [ ] Implement error logging (Sentry/Firebase Crashlytics)

### Firebase Setup
- [ ] Create Firebase project
- [ ] Enable Authentication (Email, Google)
- [ ] Set up Firestore with proper indexes
- [ ] Configure Storage for PDFs and images
- [ ] Set up Cloud Functions for emails
- [ ] Configure backup policies
- [ ] Set up monitoring and alerts

### App Store / Play Store
- [ ] Create app listings
- [ ] Prepare store screenshots
- [ ] Write app description and keywords
- [ ] Set pricing and regional availability
- [ ] Configure app signing certificates
- [ ] Submit for review

### Post-Launch
- [ ] Monitor crash reports
- [ ] Track user engagement metrics
- [ ] Gather user feedback
- [ ] Plan version updates
- [ ] Monitor server costs
- [ ] Implement user retention strategies

---

## 💰 Monetization Strategy

### Free Plan
- Up to 5 invoices/month
- Basic client management
- Standard PDF template
- Email support

### Premium Plan ($9.99/month)
- Unlimited invoices
- Unlimited clients
- Custom templates
- Advanced analytics
- Payment reminders
- Email support (faster)
- Multi-currency support

### Business Plan ($29.99/month)
- Everything in Premium +
- Team collaboration (up to 5 users)
- Expense tracking
- Advanced reports and exports
- Custom branding
- Payment gateway integration
- Thermal printer support
- Priority email support
- API access

### Enterprise Plan (Custom)
- Unlimited everything
- Dedicated account manager
- Custom integrations
- On-premises deployment option
- SLA support
- Custom development

### Revenue Streams
1. **Subscription Plans** - Monthly recurring revenue
2. **Premium Templates** - One-time purchase ($2-5 each)
3. **Payment Processing Fees** - 2.9% + $0.30 per transaction
4. **API Access** - \$99/month for developers
5. **White-Label Solution** - \$499/month for agencies
6. **Training & Consultation** - \$50-100/hour

### Conversion Strategy
- Free plan with 5 invoice limit to encourage upgrade
- Email reminders when approaching limit
- In-app notifications for premium features
- Case studies and success stories
- Referral program (20% commission)
- Annual billing discount (20% savings)

---

## 🎨 Advanced Features Implementation

### Recurring Invoices

```dart
class RecurringInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  RecurringInvoiceService(this._userId);

  Future<String> createRecurringInvoice({
    required Invoice baseInvoice,
    required String frequency, // 'weekly', 'monthly', 'quarterly', 'yearly'
    required int occurrences,
  }) async {
    try {
      final docRef = await _firestore
          .collection('recurring_invoices')
          .doc(_userId)
          .collection('list')
          .add({
        'baseInvoice': baseInvoice.toMap(),
        'frequency': frequency,
        'occurrences': occurrences,
        'createdInvoices': [],
        'nextDueDate': _calculateNextDate(DateTime.now(), frequency),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create recurring invoice: $e');
    }
  }

  DateTime _calculateNextDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'weekly':
        return current.add(Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      case 'quarterly':
        return DateTime(current.year, current.month + 3, current.day);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return current;
    }
  }

  // Cloud Function (Node.js) to run daily and generate due invoices
  // exports.processRecurringInvoices = functions.pubsub
  //   .schedule('every day 00:00').timeZone('UTC')
  //   .onRun(async (context) => {
  //     // Process all recurring invoices due today
  //   });
}
```

### Automated Payment Reminders

```dart
class PaymentReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService;
  final String _userId;

  PaymentReminderService(this._userId, this._emailService);

  Future<void> setupAutomatedReminders() async {
    try {
      // Get all unpaid invoices
      final invoices = await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .where('status', whereIn: ['sent', 'viewed', 'overdue'])
          .get();

      for (var doc in invoices.docs) {
        final invoice = Invoice.fromMap(doc.data(), doc.id);
        
        // Check if reminder should be sent
        final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;
        
        if (daysUntilDue == 0) {
          // Today is due date
          await _emailService.sendPaymentReminder(
            invoiceId: invoice.id,
            clientEmail: invoice.clientDetails.email,
            invoiceNumber: invoice.invoiceNumber,
            amountDue: invoice.balanceDue,
          );
        } else if (daysUntilDue == -1) {
          // 1 day overdue
          await _emailService.sendPaymentReminder(
            invoiceId: invoice.id,
            clientEmail: invoice.clientDetails.email,
            invoiceNumber: invoice.invoiceNumber,
            amountDue: invoice.balanceDue,
          );
        } else if (daysUntilDue == -7) {
          // 7 days overdue
          await _emailService.sendPaymentReminder(
            invoiceId: invoice.id,
            clientEmail: invoice.clientDetails.email,
            invoiceNumber: invoice.invoiceNumber,
            amountDue: invoice.balanceDue,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to setup reminders: $e');
    }
  }
}
```

### Multi-Currency Support

```dart
class CurrencyService {
  static const Map<String, String> CURRENCY_SYMBOLS = {
    'USD': '\,
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'PKR': 'Rs',
    'AED': 'د.إ',
    'SAR': 'ر.س',
  };

  static String formatCurrency(double amount, String currencyCode) {
    final symbol = CURRENCY_SYMBOLS[currencyCode] ?? currencyCode;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    // Use exchange rate API
    final response = await http.get(
      Uri.parse(
        'https://api.exchangerate-api.com/v4/latest/$fromCurrency',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rate = data['rates'][toCurrency];
      return amount * rate;
    } else {
      throw Exception('Failed to fetch exchange rates');
    }
  }
}
```

### Tax Calculation Engine

```dart
class TaxCalculationService {
  static double calculateTax(
    double amount,
    String taxType,
    double taxRate,
  ) {
    switch (taxType) {
      case 'GST': // India
      case 'VAT': // EU
        return amount * (taxRate / 100);
      case 'Sales Tax': // USA
        return amount * (taxRate / 100);
      case 'HST': // Canada
        return amount * (taxRate / 100);
      default:
        return 0;
    }
  }

  static Map<String, double> getDefaultTaxRates(String country) {
    switch (country) {
      case 'IN':
        return {'GST-5': 5, 'GST-12': 12, 'GST-18': 18, 'GST-28': 28};
      case 'US':
        return {
          'CA': 7.25,
          'TX': 8.25,
          'NY': 8.875,
          'FL': 6.0,
        };
      case 'GB':
        return {'Standard': 20, 'Reduced': 5, 'Zero': 0};
      case 'PK':
        return {'Standard': 17, 'Reduced': 0};
      default:
        return {'Standard': 0};
    }
  }
}
```

### Analytics Dashboard

```dart
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  AnalyticsService(this._userId);

  Future<Map<String, dynamic>> getMonthlyRevenue(
    {required int month, required int year}
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final invoices = await _firestore
          .collection('invoices')
          .doc(_userId)
          .collection('list')
          .where('issueDate', isGreaterThanOrEqualTo: startDate)
          .where('issueDate', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'paid')
          .get();

      double totalRevenue = 0;
      int invoiceCount = 0;

      for (var doc in invoices.docs) {
        final invoice = Invoice.fromMap(doc.data(), doc.id);
        totalRevenue += invoice.total;
        invoiceCount++;
      }

      return {
        'month': month,
        'year': year,
        'totalRevenue': totalRevenue,
        'invoiceCount': invoiceCount,
        'averageInvoiceValue': invoiceCount > 0 ? totalRevenue / invoiceCount : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch monthly revenue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getYearlyRevenue(
    {required int year}
  ) async {
    try {
      final monthlyData = <Map<String, dynamic>>[];

      for (int month = 1; month <= 12; month++) {
        final data = await getMonthlyRevenue(month: month, year: year);
        monthlyData.add(data);
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to fetch yearly revenue: $e');
    }
  }

  Future<Map<String, dynamic>> getClientMetrics() async {
    try {
      final clients = await _firestore
          .collection('clients')
          .doc(_userId)
          .collection('list')
          .get();

      int totalClients = clients.docs.length;
      double totalInvoiced = 0;
      double totalPaid = 0;
      int activeClients = 0;

      for (var doc in clients.docs) {
        final client = Client.fromMap(doc.data(), doc.id);
        totalInvoiced += client.totalInvoiced;
        totalPaid += client.totalPaid;
        if (client.invoiceCount > 0) {
          activeClients++;
        }
      }

      return {
        'totalClients': totalClients,
        'activeClients': activeClients,
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'averageClientValue': totalClients > 0 ? totalInvoiced / totalClients : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch client metrics: $e');
    }
  }
}
```

### Payment Gateway Integration (Stripe)

```dart
class StripePaymentService {
  final String _publishableKey;
  final String _secretKey;

  StripePaymentService({
    required String publishableKey,
    required String secretKey,
  })  : _publishableKey = publishableKey,
        _secretKey = secretKey;

  Future<void> initializeStripe() async {
    await Stripe.instance.initialize(publishableKey: _publishableKey);
  }

  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String invoiceId,
    required String clientEmail,
  }) async {
    try {
      // Create payment intent on server
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(), // Convert to cents
          'currency': currency.toLowerCase(),
          'metadata[invoiceId]': invoiceId,
          'receipt_email': clientEmail,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final clientSecret = json['client_secret'];

        // Present payment sheet
        await Stripe.instance.presentPaymentSheet();

        return PaymentResult.success(
          transactionId: json['id'],
          amount: amount,
          currency: currency,
        );
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      return PaymentResult.failure(error: e.toString());
    }
  }
}
```

---

## 📤 Export Features

### Excel Export

```dart
import 'package:excel/excel.dart';

class ExcelExportService {
  static Future<Uint8List> exportInvoicesToExcel(
    List<Invoice> invoices,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow([
      'Invoice Number',
      'Client Name',
      'Date',
      'Due Date',
      'Amount',
      'Status',
      'Paid',
    ]);

    // Add data rows
    for (var invoice in invoices) {
      sheet.appendRow([
        invoice.invoiceNumber,
        invoice.clientDetails.name,
        DateFormat('dd/MM/yyyy').format(invoice.issueDate),
        DateFormat('dd/MM/yyyy').format(invoice.dueDate),
        invoice.total,
        invoice.status,
        invoice.paidAmount,
      ]);
    }

    return excel.encode()!;
  }

  static Future<Uint8List> exportClientsToExcel(
    List<Client> clients,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      'Name',
      'Email',
      'Phone',
      'Company',
      'Total Invoiced',
      'Total Paid',
      'Outstanding',
    ]);

    for (var client in clients) {
      sheet.appendRow([
        client.name,
        client.email,
        client.phone,
        client.company,
        client.totalInvoiced,
        client.totalPaid,
        client.outstandingAmount,
      ]);
    }

    return excel.encode()!;
  }
}
```

### CSV Export

```dart
class CSVExportService {
  static String exportInvoicesToCSV(List<Invoice> invoices) {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln('Invoice Number,Client Name,Date,Due Date,Amount,Status,Paid Amount');
    
    // Data rows
    for (var invoice in invoices) {
      buffer.writeln(
        '${invoice.invoiceNumber},'
        '${invoice.clientDetails.name},'
        '${DateFormat('dd/MM/yyyy').format(invoice.issueDate)},'
        '${DateFormat('dd/MM/yyyy').format(invoice.dueDate)},'
        '${invoice.total},'
        '${invoice.status},'
        '${invoice.paidAmount}',
      );
    }
    
    return buffer.toString();
  }
}
```

---

## 🔔 Notification System

### Push Notifications

```dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeNotifications() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> sendPaymentReceivedNotification({
    required String userId,
    required String invoiceNumber,
    required double amount,
  }) async {
    // Send via Cloud Function
    await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
      'userId': userId,
      'title': 'Payment Received',
      'body': 'Payment received for invoice $invoiceNumber: \$amount',
      'type': 'payment_received',
    });
  }

  Future<void> sendInvoiceOverdueNotification({
    required String userId,
    required String invoiceNumber,
    required double amount,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
      'userId': userId,
      'title': 'Invoice Overdue',
      'body': 'Invoice $invoiceNumber is now overdue. Amount due: \$amount',
      'type': 'invoice_overdue',
    });
  }

  void _handleNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'payment_received':
        // Navigate to payment details
        break;
      case 'invoice_overdue':
        // Navigate to invoice
        break;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
```

---

## 🧪 Testing Strategy

### Unit Tests

```dart
void main() {
  group('Invoice Repository Tests', () {
    late InvoiceRepository repository;

    setUp(() {
      repository = InvoiceRepository('test_user_id');
    });

    test('Create invoice with valid data', () async {
      final invoice = Invoice(
        invoiceNumber: 'INV-001',
        businessProfileId: 'profile_1',
        clientId: 'client_1',
        clientDetails: ClientDetails(
          name: 'Test Client',
          email: 'test@example.com',
          phone: '1234567890',
          address: Address(
            street: '123 Main St',
            city: 'Test City',
            state: 'TS',
            zipCode: '12345',
            country: 'Test Country',
          ),
        ),
        items: [
          InvoiceItem(
            productId: 'product_1',
            name: 'Test Product',
            description: 'A test product',
            quantity: 2,
            unit: 'item',
            rate: 50,
            taxRate: 10,
            taxAmount: 10,
            amount: 100,
            total: 110,
          ),
        ],
        subtotal: 100,
        totalTax: 10,
        discount: Discount(type: 'percentage', value: 0, amount: 0),
        shippingCost: 5,
        total: 115,
        currency: 'USD',
        status: 'draft',
        dueDate: DateTime.now().add(Duration(days: 30)),
        issueDate: DateTime.now(),
        notes: 'Test notes',
        terms: 'Test terms',
      );

      final id = await repository.createInvoice(invoice);
      expect(id, isNotEmpty);
    });

    test('Get invoice by ID', () async {
      final invoice = await repository.getInvoice('invoice_1');
      expect(invoice, isNotNull);
      expect(invoice.invoiceNumber, 'INV-001');
    });
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('Invoice list displays items', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: InvoiceListScreen(),
    ));

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(InvoiceCard), findsWidgets);
  });

  testWidgets('Tap on invoice navigates to detail', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: InvoiceListScreen(),
    ));

    await tester.tap(find.byType(InvoiceCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(InvoiceDetailScreen), findsOneWidget);
  });
}
```

---

## 📚 Model Classes

```dart
class Invoice {
  final String id;
  final String invoiceNumber;
  final String businessProfileId;
  final String clientId;
  final ClientDetails clientDetails;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalTax;
  final Discount discount;
  final double shippingCost;
  final double total;
  final String currency;
  final String status;
  final DateTime dueDate;
  final DateTime issueDate;
  final DateTime? paidDate;
  final double paidAmount;
  final double balanceDue;
  final String paymentMethod;
  final String notes;
  final String terms;
  final List<String> attachments;
  final String? pdfUrl;
  final bool emailSent;
  final DateTime? emailSentAt;
  final DateTime? viewedAt;
  final int remindersSent;
  final DateTime? lastReminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.businessProfileId,
    required this.clientId,
    required this.clientDetails,
    required this.items,
    required this.subtotal,
    required this.totalTax,
    required this.discount,
    required this.shippingCost,
    required this.total,
    required this.currency,
    required this.status,
    required this.dueDate,
    required this.issueDate,
    this.paidDate,
    this.paidAmount = 0,
    this.balanceDue = 0,
    this.paymentMethod = '',
    this.notes = '',
    this.terms = '',
    this.attachments = const [],
    this.pdfUrl,
    this.emailSent = false,
    this.emailSentAt,
    this.viewedAt,
    this.remindersSent = 0,
    this.lastReminderAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'businessProfileId': businessProfileId,
      'clientId': clientId,
      'clientDetails': clientDetails.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'totalTax': totalTax,
      'discount': discount.toMap(),
      'shippingCost': shippingCost,
      'total': total,
      'currency': currency,
      'status': status,
      'dueDate': dueDate,
      'issueDate': issueDate,
      'paidDate': paidDate,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'terms': terms,
      'attachments': attachments,
      'pdfUrl': pdfUrl,
      'emailSent': emailSent,
      'emailSentAt': emailSentAt,
      'viewedAt': viewedAt,
      'remindersSent': remindersSent,
      'lastReminderAt': lastReminderAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      businessProfileId: map['businessProfileId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientDetails: ClientDetails.fromMap(map['clientDetails'] ?? {}),
      items: List<InvoiceItem>.from(
        (map['items'] as List<dynamic>?)?.map((x) => InvoiceItem.fromMap(x)) ?? [],
      ),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      totalTax: (map['totalTax'] ?? 0).toDouble(),
      discount: Discount.fromMap(map['discount'] ?? {}),
      shippingCost: (map['shippingCost'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'draft',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      issueDate: (map['issueDate'] as Timestamp).toDate(),
      paidDate: map['paidDate'] != null ? (map['paidDate'] as Timestamp).toDate() : null,
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      balanceDue: (map['balanceDue'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      notes: map['notes'] ?? '',
      terms: map['terms'] ?? '',
      attachments: List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      pdfUrl: map['pdfUrl'],
      emailSent: map['emailSent'] ?? false,
      emailSentAt: map['emailSentAt'] != null ? (map['emailSentAt'] as Timestamp).toDate() : null,
      viewedAt: map['viewedAt'] != null ? (map['viewedAt'] as Timestamp).toDate() : null,
      remindersSent: map['remindersSent'] ?? 0,
      lastReminderAt: map['lastReminderAt'] != null ? (map['lastReminderAt'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class InvoiceItem {
  final String productId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double taxRate;
  final double taxAmount;
  final double amount;
  final double total;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.taxRate,
    required this.taxAmount,
    required this.amount,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'amount': amount,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }
}

class Discount {
  final String type; // 'percentage' or 'fixed'
  final double value;
  final double amount;

  Discount({
    required this.type,
    required this.value,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'amount': amount,
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      type: map['type'] ?? 'percentage',
      value: (map['value'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String taxId;
  final Address address;
  final String notes;
  final List<String> tags;
  final double totalInvoiced;
  final double totalPaid;
  final double outstandingAmount;
  final int invoiceCount;
  final DateTime? lastInvoiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.taxId,
    required this.address,
    this.notes = '',
    this.tags = const [],
    this.totalInvoiced = 0,
    this.totalPaid = 0,
    this.outstandingAmount = 0,
    this.invoiceCount = 0,
    this.lastInvoiceDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'taxId': taxId,
      'address': address.toMap(),
      'notes': notes,
      'tags': tags,
      'totalInvoiced': totalInvoiced,
      'totalPaid': totalPaid,
      'outstandingAmount': outstandingAmount,
      'invoiceCount': invoiceCount,
      'lastInvoiceDate': lastInvoiceDate,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    return Client(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'] ?? '',
      taxId: map['taxId'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
      notes: map['notes'] ?? '',
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      totalInvoiced: (map['totalInvoiced'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      outstandingAmount: (map['outstandingAmount'] ?? 0).toDouble(),
      invoiceCount: map['invoiceCount'] ?? 0,
      lastInvoiceDate: map['lastInvoiceDate'] != null ? (map['lastInvoiceDate'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
    );
  }
}

class ClientDetails {
  final String name;
  final String email;
  final String phone;
  final Address address;

  ClientDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address.toMap(),
    };
  }

  factory ClientDetails.fromMap(Map<String, dynamic> map) {
    return ClientDetails(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final double taxRate;
  final String category;
  final String sku;
  final int stockQuantity;
  final bool isService;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.taxRate,
    required this.category,
    required this.sku,
    required this.stockQuantity,
    required this.isService,
    required this.isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'taxRate': taxRate,
      'category': category,
      'sku': sku,
      'stockQuantity': stockQuantity,
      'isService': isService,
      'isActive': isActive,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'item',
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      sku: map['sku'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      isService: map['isService'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class Business {
  final String id;
  final String businessName;
  final String? logo;
  final String email;
  final String phone;
  final String website;
  final Address address;
  final String taxId;
  final BankDetails? bankDetails;
  final InvoiceSettings invoiceSettings;
  final String paymentTerms;
  final String notes;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.businessName,
    this.logo,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.taxId,
    this.bankDetails,
    required this.invoiceSettings,
    required this.paymentTerms,
    required this.notes,
    required this.isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logo': logo,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address.toMap(),
      'taxId': taxId,
      'bankDetails': bankDetails?.toMap(),
      'invoiceSettings': invoiceSettings.toMap(),
      'paymentTerms': paymentTerms,
      'notes': notes,
      'isDefault': isDefault,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    return Business(
      id: id,
      businessName: map['businessName'] ?? '',
      logo: map['logo'],
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
      taxId: map['taxId'] ?? '',
      bankDetails: map['bankDetails'] != null ? BankDetails.fromMap(map['bankDetails']) : null,
      invoiceSettings: InvoiceSettings.fromMap(map['invoiceSettings'] ?? {}),
      paymentTerms: map['paymentTerms'] ?? '',
      notes: map['notes'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class BankDetails {
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String swiftCode;

  BankDetails({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.swiftCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountName': accountName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'swiftCode': swiftCode,
    };
  }

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      bankName: map['bankName'] ?? '',
      swiftCode: map['swiftCode'] ?? '',
    );
  }
}

class InvoiceSettings {
  final String prefix;
  final int startNumber;
  final int currentNumber;
  final String numberFormat;

  InvoiceSettings({
    required this.prefix,
    required this.startNumber,
    required this.currentNumber,
    required this.numberFormat,
  });

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'startNumber': startNumber,
      'currentNumber': currentNumber,
      'numberFormat': numberFormat,
    };
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> map) {
    return InvoiceSettings(
      prefix: map['prefix'] ?? 'INV-',
      startNumber: map['startNumber'] ?? 1,
      currentNumber: map['currentNumber'] ?? 0,
      numberFormat: map['numberFormat'] ?? 'INV-{YYYY}-{####}',
    );
  }
}

class Payment {
  final String id;
  final String invoiceId;
  final String clientId;
  final double amount;
  final String paymentMethod;
  final String referenceNumber;
  final String notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.clientId,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
    required this.paymentDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'clientId': clientId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'paymentDate': paymentDate,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      invoiceId: map['invoiceId'] ?? '',
      clientId: map['clientId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      referenceNumber: map['referenceNumber'] ?? '',
      notes: map['notes'] ?? '',
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
```

---

## 🔗 API Endpoints Reference (Firebase Cloud Functions)

### Invoice Endpoints

```
POST /invoices/create
- Creates new invoice
- Body: { invoice object }
- Returns: { invoiceId, invoiceNumber, status }

GET /invoices/{invoiceId}
- Retrieves invoice details
- Returns: { invoice object }

PUT /invoices/{invoiceId}
- Updates invoice
- Body: { updated fields }
- Returns: { status, updatedAt }

DELETE /invoices/{invoiceId}
- Deletes invoice
- Returns: { status, deletedAt }

GET /invoices/status/{status}
- Gets invoices by status
- Returns: { invoices array }

POST /invoices/{invoiceId}/send
- Sends invoice via email
- Body: { clientEmail }
- Returns: { status, emailSentAt }

POST /invoices/{invoiceId}/pdf
- Generates PDF
- Returns: { pdfUrl }

POST /invoices/{invoiceId}/mark-as-paid
- Marks invoice as paid
- Body: { amount, paymentMethod, date }
- Returns: { status, paidAt }
```

### Client Endpoints

```
POST /clients/create
- Creates new client
- Body: { client object }
- Returns: { clientId, status }

GET /clients/{clientId}
- Retrieves client details
- Returns: { client object }

PUT /clients/{clientId}
- Updates client
- Body: { updated fields }
- Returns: { status, updatedAt }

DELETE /clients/{clientId}
- Deletes client
- Returns: { status }

GET /clients/list
- Gets all clients
- Query: ?limit=20&offset=0
- Returns: { clients array, total }

GET /clients/{clientId}/invoices
- Gets client invoice history
- Returns: { invoices array }
```

### Product Endpoints

```
POST /products/create
- Creates new product
- Body: { product object }
- Returns: { productId, status }

GET /products/{productId}
- Retrieves product details
- Returns: { product object }

PUT /products/{productId}
- Updates product
- Body: { updated fields }
- Returns: { status }

DELETE /products/{productId}
- Deletes product
- Returns: { status }

GET /products/list
- Gets all products
- Query: ?category=&limit=20
- Returns: { products array }
```

---

## 🚦 Common Implementation Issues & Solutions

### Issue 1: Slow Invoice Loading
**Problem:** Invoices take too long to load from Firestore

**Solution:**
```dart
// Use pagination
Stream<List<Invoice>> getInvoicesPaginated({
  required int limit,
  DocumentSnapshot? lastDocument,
}) {
  var query = _firestore
      .collection('invoices')
      .doc(_userId)
      .collection('list')
      .orderBy('createdAt', descending: true)
      .limit(limit);

  if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
  }

  return query.snapshots().map((snapshot) =>
      snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList());
}
```

### Issue 2: PDF Generation Out of Memory
**Problem:** Large invoices cause OutOfMemory errors during PDF generation

**Solution:**
```dart
// Generate PDF asynchronously on separate isolate
Future<Uint8List> generatePDFIsolate(Invoice invoice, Business business) async {
  return compute(_generatePDF, {'invoice': invoice, 'business': business});
}

static Uint8List _generatePDF(Map<String, dynamic> data) {
  // PDF generation logic here
  return pdfData;
}
```

### Issue 3: Duplicate Invoices
**Problem:** Network issues cause duplicate invoice creation

**Solution:**
```dart
// Use idempotency keys
Future<String> createInvoiceIdempotent(Invoice invoice, String idempotencyKey) async {
  try {
    final existingInvoice = await _firestore
        .collection('invoices')
        .doc(_userId)
        .collection('list')
        .where('idempotencyKey', isEqualTo: idempotencyKey)
        .limit(1)
        .get();

    if (existingInvoice.docs.isNotEmpty) {
      return existingInvoice.docs.first.id;
    }

    final docRef = await _firestore
        .collection('invoices')
        .doc(_userId)
        .collection('list')
        .add({
      ...invoice.toMap(),
      'idempotencyKey': idempotencyKey,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  } catch (e) {
    throw Exception('Failed to create invoice: $e');
  }
}
```

### Issue 4: Email Delivery Failures
**Problem:** Emails not reaching clients

**Solution:**
```dart
// Implement retry logic with exponential backoff
Future<void> sendEmailWithRetry({
  required String invoiceId,
  required String email,
  int retries = 3,
}) async {
  for (int i = 0; i < retries; i++) {
    try {
      await _emailService.sendInvoiceEmail(
        invoiceId: invoiceId,
        clientEmail: email,
      );
      return;
    } catch (e) {
      if (i == retries - 1) rethrow;
      
      // Exponential backoff: 2s, 4s, 8s
      await Future.delayed(Duration(seconds: pow(2, i + 1).toInt()));
    }
  }
}
```

---

## 📖 Getting Started Guide

### Step 1: Project Setup

```bash
# Create Flutter project
flutter create invoice_app
cd invoice_app

# Add dependencies
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage firebase_functions
flutter pub add provider riverpod
flutter pub add pdf intl
flutter pub add http dio

# Get packages
flutter pub get
```

### Step 2: Firebase Configuration

1. Create Firebase project at https://console.firebase.google.com
2. Add iOS and Android apps
3. Download configuration files:
   - iOS: `GoogleService-Info.plist` → ios/Runner/
   - Android: `google-services.json` → android/app/

### Step 3: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/invoices': (context) => const InvoiceListScreen(),
        '/invoice/create': (context) => const InvoiceFormScreen(),
        '/clients': (context) => const ClientListScreen(),
        '/products': (context) => const ProductListScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
```

### Step 4: Set Up Authentication

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
```

### Step 5: Build First Screen

```dart
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
```

---

## 🎯 Next Steps & Recommendations

1. **Start with MVP** - Focus on core features first (invoices, clients, basic PDF)
2. **Use Clean Architecture** - Separate concerns: UI, Business Logic, Data
3. **Implement State Management** - Choose Provider, Riverpod, or Bloc early
4. **Test Thoroughly** - Write unit tests for business logic, widget tests for UI
5. **Monitor Performance** - Use Firebase Analytics to track user behavior
6. **Gather Feedback** - Launch beta with limited users first
7. **Iterate Quickly** - Release updates monthly based on feedback
8. **Plan Monetization** - Implement subscription system early

---

## 📞 Support & Resources

- **Firebase Docs:** https://firebase.flutter.dev/
- **Flutter Docs:** https://flutter.dev/docs
- **Provider Documentation:** https://pub.dev/packages/provider
- **Riverpod Documentation:** https://riverpod.dev/
- **PDF Package:** https://pub.dev/packages/pdf

---

**Last Updated:** October 2024
**Status:** Production Ready
**Version:** 1.0.0