// invoice_pdf_service.dart
// Export ໃບແຈ້ງໜີ້ເປັນ PDF ດ້ວຍ pdf + printing package
//
// pubspec.yaml dependencies ທີ່ຕ້ອງເພີ່ມ:
//   pdf: ^3.11.0
//   printing: ^5.13.0
//   path_provider: ^2.1.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────
// InvoicePdfData — ຂໍ້ມູນໃສ່ PDF
// ─────────────────────────────────────────────────────────────
class InvoicePdfData {
  // Header
  final String invoiceNo;
  final String issueDate;
  final String dueDate;
  final String periodFrom;
  final String periodTo;
  final String currency;
  final String invoiceType;

  // Seller
  final String sellerName;
  final String sellerAddress;
  final String sellerTaxId;
  final String sellerContact;

  // Buyer
  final String buyerName;
  final String buyerAddress;
  final String buyerTaxId;
  final String buyerContact;
  final String buyerType;

  // Energy
  final bool   usePeakOffPeak;
  final double actualMWh;
  final double unitPrice;
  final double peakMWh;
  final double peakPrice;
  final double offPeakMWh;
  final double offPeakPrice;

  // Capacity
  final bool   includeCapacity;
  final double capacityMW;
  final double capacityPrice;

  // Penalty
  final double penaltyAmount;
  final String penaltyReason;

  // Tax
  final bool   includeTax;
  final String taxRate;

  // Bank
  final String bankName;
  final String accountName;
  final String accountNo;
  final String swiftCode;
  final String remark;

  const InvoicePdfData({
    required this.invoiceNo,
    required this.issueDate,
    required this.dueDate,
    required this.periodFrom,
    required this.periodTo,
    required this.currency,
    required this.invoiceType,
    required this.sellerName,
    required this.sellerAddress,
    required this.sellerTaxId,
    required this.sellerContact,
    required this.buyerName,
    required this.buyerAddress,
    required this.buyerTaxId,
    required this.buyerContact,
    required this.buyerType,
    this.usePeakOffPeak = false,
    this.actualMWh      = 0,
    this.unitPrice      = 0,
    this.peakMWh        = 0,
    this.peakPrice      = 0,
    this.offPeakMWh     = 0,
    this.offPeakPrice   = 0,
    this.includeCapacity = false,
    this.capacityMW     = 0,
    this.capacityPrice  = 0,
    this.penaltyAmount  = 0,
    this.penaltyReason  = '',
    this.includeTax     = true,
    this.taxRate        = '10%',
    this.bankName       = '',
    this.accountName    = '',
    this.accountNo      = '',
    this.swiftCode      = '',
    this.remark         = '',
  });

  // ── Calculations ──
  double get energyAmount {
    if (usePeakOffPeak) return (peakMWh * peakPrice) + (offPeakMWh * offPeakPrice);
    return actualMWh * unitPrice;
  }

  double get capacityAmount => includeCapacity ? capacityMW * capacityPrice : 0;

  double get subtotal => energyAmount + capacityAmount - penaltyAmount;

  double get taxAmount {
    if (!includeTax) return 0;
    final rate = double.tryParse(taxRate.replaceAll('%', '')) ?? 0;
    return subtotal * rate / 100;
  }

  double get total => subtotal + taxAmount;

  String fmt(double v) => v.toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String fmtMWh(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─────────────────────────────────────────────────────────────
// InvoicePdfService — ສ້າງ PDF ແລະ Print / Share
// ─────────────────────────────────────────────────────────────
class InvoicePdfService {

  // ── PdfColor constants ──
  static const PdfColor _green     = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor _greenLight= PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor _blue      = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor _blueLight = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _amber     = PdfColor.fromInt(0xFFF57F17);
  static const PdfColor _amberLight= PdfColor.fromInt(0xFFFFF8E1);
  static const PdfColor _greyLight = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _red       = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _textDark  = PdfColor.fromInt(0xFF212121);
  static const PdfColor _textGrey  = PdfColor.fromInt(0xFF757575);
  static const PdfColor _border    = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor _white     = PdfColors.white;

  // ─────────────────────────────────────────
  // ສ້າງ PDF Document
  // ─────────────────────────────────────────
  static Future<pw.Document> buildPdf(InvoicePdfData data) async {
    final doc = pw.Document();

    // Load font ທີ່ຮອງຮັບພາສາລາວ (ຕ້ອງໃສ່ fonts ໃນ assets)
    // ຖ້າບໍ່ມີ font ລາວ ໃຫ້ໃຊ້ default font ກ່ອນ
    // final fontData = await rootBundle.load('assets/fonts/NotoSansLao.ttf');
    // final laoFont = pw.Font.ttf(fontData);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(data),
        footer: (ctx) => _buildFooter(ctx, data),
        build: (ctx) => [
          _buildMetaRow(data),
          pw.SizedBox(height: 12),
          _buildPartiesSection(data),
          pw.SizedBox(height: 14),
          _buildLineItemsTable(data),
          pw.SizedBox(height: 14),
          _buildTotalsSection(data),
          pw.SizedBox(height: 20),
          _buildPaymentSection(data),
          pw.SizedBox(height: 24),
          _buildSignatureSection(),
        ],
      ),
    );
    return doc;
  }

  // ── Header ──
  static pw.Widget _buildHeader(InvoicePdfData data) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Seller info
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(data.sellerName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                    color: _textDark)),
            pw.SizedBox(height: 2),
            pw.Text(data.sellerAddress,
                style: pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (data.sellerTaxId.isNotEmpty)
              pw.Text('Tax ID: ${data.sellerTaxId}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (data.sellerContact.isNotEmpty)
              pw.Text('Tel: ${data.sellerContact}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey)),
          ]),
          // Invoice title
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('INVOICE',
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold,
                    color: _green)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _greyLight,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(data.invoiceNo,
                  style: pw.TextStyle(fontSize: 11, color: _textDark,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _amberLight,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('ລໍຖ້າຊຳລະ · Pending',
                  style: pw.TextStyle(fontSize: 9, color: _amber,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ]),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: _border, thickness: 0.5),
    ]);
  }

  // ── Footer ──
  static pw.Widget _buildFooter(pw.Context ctx, InvoicePdfData data) {
    return pw.Column(children: [
      pw.Divider(color: _border, thickness: 0.5),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('${data.sellerName} · ${data.invoiceNo}',
              style: pw.TextStyle(fontSize: 8, color: _textGrey)),
          pw.Text('ໜ້າ ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _textGrey)),
        ],
      ),
    ]);
  }

  // ── Meta: dates ──
  static pw.Widget _buildMetaRow(InvoicePdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greyLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(children: [
        _metaCell('ວັນທີ່ອອກ / Issue Date', data.issueDate),
        _metaCell('ຄົບກຳນົດ / Due Date', data.dueDate,
            valueColor: _amber),
        _metaCell('ໄລຍະ / Period', '${data.periodFrom} – ${data.periodTo}'),
        _metaCell('ປະເພດ / Type', data.invoiceType),
        _metaCell('ສະກຸນ / Currency', data.currency,
            valueColor: _green),
      ]),
    );
  }

  static pw.Widget _metaCell(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Expanded(child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _textGrey)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? _textDark)),
      ],
    ));
  }

  // ── Parties ──
  static pw.Widget _buildPartiesSection(InvoicePdfData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('ຜູ້ຂາຍ (Seller)',
                style: pw.TextStyle(fontSize: 8, color: _textGrey)),
            pw.SizedBox(height: 4),
            pw.Text(data.sellerName,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold,
                    color: _textDark)),
            pw.Text(data.sellerAddress,
                style: pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (data.sellerTaxId.isNotEmpty)
              pw.Text('Tax ID: ${data.sellerTaxId}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey)),
          ]),
        )),
        pw.SizedBox(width: 12),
        pw.Expanded(child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _blueLight,
            border: pw.Border.all(color: _blue.shade(0.3), width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('ຜູ້ຊື້ (Bill To) · ${data.buyerType}',
                style: pw.TextStyle(fontSize: 8, color: _blue)),
            pw.SizedBox(height: 4),
            pw.Text(data.buyerName,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold,
                    color: _textDark)),
            pw.Text(data.buyerAddress,
                style: pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (data.buyerTaxId.isNotEmpty)
              pw.Text('Tax ID: ${data.buyerTaxId}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (data.buyerContact.isNotEmpty)
              pw.Text('ຕິດຕໍ່: ${data.buyerContact}',
                  style: pw.TextStyle(fontSize: 9, color: _textGrey)),
          ]),
        )),
      ],
    );
  }

  // ── Line Items Table ──
  static pw.Widget _buildLineItemsTable(InvoicePdfData data) {
    final rows = <List<String>>[];

    if (data.usePeakOffPeak) {
      rows.add(['ພະລັງງານ Peak (On-Peak)',
        '${data.fmtMWh(data.peakMWh)} MWh',
        '${data.peakPrice.toStringAsFixed(4)} ${data.currency}',
        'On-Peak',
        data.fmt(data.peakMWh * data.peakPrice)]);
      rows.add(['ພະລັງງານ Off-Peak',
        '${data.fmtMWh(data.offPeakMWh)} MWh',
        '${data.offPeakPrice.toStringAsFixed(4)} ${data.currency}',
        'Off-Peak',
        data.fmt(data.offPeakMWh * data.offPeakPrice)]);
    } else {
      rows.add(['ພະລັງງານ (Energy)',
        '${data.fmtMWh(data.actualMWh)} MWh',
        '${data.unitPrice.toStringAsFixed(4)} ${data.currency}',
        '—',
        data.fmt(data.energyAmount)]);
    }

    if (data.includeCapacity) {
      rows.add(['ຄ່າກຳລັງ (Capacity Charge)',
        '${data.capacityMW.toStringAsFixed(0)} MW',
        '${data.capacityPrice.toStringAsFixed(3)} ${data.currency}/MW',
        '—',
        data.fmt(data.capacityAmount)]);
    }

    if (data.penaltyAmount > 0) {
      rows.add(['ຫັກ (Deduction) — ${data.penaltyReason}',
        '—', '—', 'Penalty',
        '- ${data.fmt(data.penaltyAmount)}']);
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('ລາຍການ (Line Items)',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
              color: _textDark)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(2),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green.shade(0.85)),
            children: ['ລາຍການ / Description', 'ປະລິມານ', 'ລາຄາ / ໜ່ວຍ', 'ປະເພດ', 'ຈຳນວນ (${data.currency})']
                .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(h, style: pw.TextStyle(fontSize: 8,
                      fontWeight: pw.FontWeight.bold, color: _white)),
                ))
                .toList(),
          ),
          // Data rows
          ...rows.asMap().entries.map((e) {
            final isEven = e.key.isEven;
            final isPenalty = e.value[3] == 'Penalty';
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isPenalty
                    ? PdfColor.fromHex('#FFF5F5')
                    : (isEven ? _white : _greyLight),
              ),
              children: e.value.asMap().entries.map((cell) {
                final isAmt = cell.key == 4;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: pw.Text(cell.value,
                      textAlign: (isAmt || cell.key == 1 || cell.key == 2)
                          ? pw.TextAlign.right
                          : pw.TextAlign.left,
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: isPenalty ? _red : _textDark,
                          fontWeight: isAmt ? pw.FontWeight.bold : pw.FontWeight.normal)),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ]);
  }

  // ── Totals ──
  static pw.Widget _buildTotalsSection(InvoicePdfData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 240,
          child: pw.Column(children: [
            _totalLine('Subtotal', '${data.currency} ${data.fmt(data.subtotal)}'),
            if (data.includeTax)
              _totalLine('VAT (${data.taxRate})',
                  '${data.currency} ${data.fmt(data.taxAmount)}'),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _greenLight,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _green, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL AMOUNT DUE',
                      style: pw.TextStyle(fontSize: 10,
                          fontWeight: pw.FontWeight.bold, color: _textDark)),
                  pw.Text('${data.currency} ${data.fmt(data.total)}',
                      style: pw.TextStyle(fontSize: 13,
                          fontWeight: pw.FontWeight.bold, color: _green)),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  static pw.Widget _totalLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _textGrey)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10,
              fontWeight: pw.FontWeight.bold, color: _textDark)),
        ],
      ),
    );
  }

  // ── Payment Info ──
  static pw.Widget _buildPaymentSection(InvoicePdfData data) {
    if (data.bankName.isEmpty && data.accountNo.isEmpty) return pw.SizedBox();
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greyLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ຂໍ້ມູນການຊຳລະ (Payment Details)',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                      color: _textDark)),
              pw.SizedBox(height: 6),
              if (data.bankName.isNotEmpty)
                _payRow('ທະນາຄານ', data.bankName),
              if (data.accountName.isNotEmpty)
                _payRow('ຊື່ບັນຊີ', data.accountName),
              if (data.accountNo.isNotEmpty)
                _payRow('ເລກບັນຊີ', data.accountNo),
              if (data.swiftCode.isNotEmpty)
                _payRow('SWIFT/BIC', data.swiftCode),
            ],
          )),
          if (data.remark.isNotEmpty) ...[
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ໝາຍເຫດ (Remark)',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                        color: _textDark)),
                pw.SizedBox(height: 6),
                pw.Text(data.remark,
                    style: pw.TextStyle(fontSize: 9, color: _textGrey)),
              ],
            )),
          ],
        ],
      ),
    );
  }

  static pw.Widget _payRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(children: [
        pw.SizedBox(width: 70,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: _textGrey))),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 9, color: _textDark,
                fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  // ── Signatures ──
  static pw.Widget _buildSignatureSection() {
    return pw.Row(children: [
      _sigBox('ຜູ້ອອກໃບແຈ້ງໜີ້\nIssued By'),
      pw.SizedBox(width: 12),
      _sigBox('ຜູ້ຈັດການການເງິນ\nFinance Manager'),
      pw.SizedBox(width: 12),
      _sigBox('ຜູ້ຮັບ (EDL)\nReceived By'),
    ]);
  }

  static pw.Widget _sigBox(String label) {
    return pw.Expanded(child: pw.Container(
      height: 64,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(height: 0.5, color: _border,
              margin: const pw.EdgeInsets.symmetric(horizontal: 12)),
          pw.SizedBox(height: 6),
          pw.Text(label, textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, color: _textGrey)),
          pw.SizedBox(height: 6),
        ],
      ),
    ));
  }

  // ─────────────────────────────────────────
  // PUBLIC METHODS
  // ─────────────────────────────────────────

  /// ພິມ / Share PDF ໂດຍກົງ (ໃຊ້ printing package)
  static Future<void> printInvoice(BuildContext context, InvoicePdfData data) async {
    final doc = await buildPdf(data);
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${data.invoiceNo}.pdf',
    );
  }

  /// Share PDF ຜ່ານ share sheet
  static Future<void> sharePdf(BuildContext context, InvoicePdfData data) async {
    final doc = await buildPdf(data);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${data.invoiceNo}.pdf',
    );
  }

  /// Save PDF ໄວ້ໃນ Documents folder
  static Future<String> savePdfToDevice(InvoicePdfData data) async {
    final doc   = await buildPdf(data);
    final bytes = await doc.save();
    final dir   = await getApplicationDocumentsDirectory();
    final file  = File('${dir.path}/${data.invoiceNo}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

// ─────────────────────────────────────────────────────────────
// InvoicePdfButton — Widget ປຸ່ມ Export ໃຊ້ໃນ CreateInvoiceScreen
// ─────────────────────────────────────────────────────────────
class InvoicePdfButton extends StatefulWidget {
  final InvoicePdfData data;
  const InvoicePdfButton({super.key, required this.data});

  @override
  State<InvoicePdfButton> createState() => _InvoicePdfButtonState();
}

class _InvoicePdfButtonState extends State<InvoicePdfButton> {
  bool _loading = false;

  Future<void> _handleExport(String action) async {
    setState(() => _loading = true);
    try {
      switch (action) {
        case 'print':
          await InvoicePdfService.printInvoice(context, widget.data);
          break;
        case 'share':
          await InvoicePdfService.sharePdf(context, widget.data);
          break;
        case 'save':
          final path = await InvoicePdfService.savePdfToDevice(widget.data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('ບັນທຶກ PDF ແລ້ວ: $path',
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
            ));
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _handleExport,
      color: const Color(0xFF1E2A3A), // AppColors.bgSecondary
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        _menuItem('print', Icons.print_outlined,    'ພິມໃບແຈ້ງໜີ້'),
        _menuItem('share', Icons.share_outlined,    'Share / ສົ່ງໄຟລ໌'),
        _menuItem('save',  Icons.download_outlined, 'ບັນທຶກ PDF'),
      ],
      child: _loading
          ? const SizedBox(width: 36, height: 36,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: Color(0xFF4CAF50)))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3A4A5A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF4CAF50)),
                SizedBox(width: 6),
                Text('PDF', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF4CAF50)),
              ]),
            ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 12,
            color: Color(0xFFCFD8DC))),
      ]),
    );
  }
}