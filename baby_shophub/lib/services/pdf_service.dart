import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/business_model.dart';

class PDFService {
  static Future<Uint8List> generateInvoicePDF(
    Invoice invoice,
    Business business,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with logo and business info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.businessName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(business.address.street),
                    pw.Text(
                      '${business.address.city}, ${business.address.state}',
                    ),
                    pw.Text(business.email),
                    pw.Text(business.phone),
                  ],
                ),
                if (business.logo != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Text('Logo would be here'),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Invoice details
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
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
                pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(invoice.status),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    invoice.status.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Bill to section
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(invoice.clientDetails.name),
                pw.Text(invoice.clientDetails.email),
                pw.Text(invoice.clientDetails.phone),
                pw.Text(invoice.clientDetails.address.street),
                pw.Text(
                  '${invoice.clientDetails.address.city}, ${invoice.clientDetails.address.state} ${invoice.clientDetails.address.zipCode}',
                ),
                pw.Text(invoice.clientDetails.address.country),
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
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Text(
                      'Description',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Rate',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Tax',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                ...invoice.items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.name,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            item.description,
                            style: pw.TextStyle(fontSize: 9),
                          ),
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
              child: pw.Container(
                width: 200,
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
                          pw.Text(
                            '-\$${invoice.discount.amount.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    if (invoice.shippingCost > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Shipping:'),
                          pw.Text(
                            '\$${invoice.shippingCost.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '\$${invoice.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Notes and terms
            if (invoice.notes.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(invoice.notes),
                ],
              ),
            pw.SizedBox(height: 10),
            if (invoice.terms.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Terms & Conditions:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(invoice.terms),
                ],
              ),
            pw.SizedBox(height: 20),

            // Bank details
            if (business.bankDetails != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Payment Details:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Bank: ${business.bankDetails!.bankName}'),
                  pw.Text('Account: ${business.bankDetails!.accountNumber}'),
                  pw.Text('SWIFT: ${business.bankDetails!.swiftCode}'),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColors.green;
      case 'overdue':
        return PdfColors.red;
      case 'sent':
      case 'viewed':
        return PdfColors.orange;
      case 'draft':
        return PdfColors.grey;
      default:
        return PdfColors.blue;
    }
  }
}
