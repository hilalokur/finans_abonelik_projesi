import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/subscription.dart';
import 'currency_service.dart';
import 'subscription_service.dart';

class ReportExportService {
  ReportExportService._();
  static final instance = ReportExportService._();

  Future<bool> exportCsv({
    required String currency,
    required List<SubscriptionModel> subscriptions,
  }) async {
    final rows = <List<String>>[
      [
        'Service',
        'Category',
        'Original amount',
        'Original currency',
        'Monthly estimate',
        'Display currency',
        'Next renewal',
        'Status',
      ],
      for (final item in subscriptions)
        [
          item.name,
          item.categoryName,
          item.amount.toStringAsFixed(2),
          item.currency,
          _convert(
                SubscriptionService.instance.monthlyEquivalent(item),
                item.currency,
                currency,
              )?.toStringAsFixed(2) ??
              '',
          currency,
          item.nextBillingDate.toIso8601String().split('T').first,
          item.isActive ? 'Active' : 'Cancelled',
        ],
    ];
    final csv =
        '\uFEFF${rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n')}';
    return await FilePicker.saveFile(
          fileName: 'subtrack-report.csv',
          mimeType: 'text/csv',
          bytes: Uint8List.fromList(utf8.encode(csv)),
        ) !=
        null;
  }

  Future<bool> exportPdf({
    required String currency,
    required List<SubscriptionModel> subscriptions,
    required double monthlyTotal,
  }) async {
    final ratesMissing = SubscriptionService.instance.hasMissingRatesFor(
      currency,
    );
    final sorted = [...subscriptions]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final lines = <String>[
      'SUBTRACK Subscription Report',
      ratesMissing
          ? 'Monthly estimated total: unavailable (missing rate)'
          : 'Monthly estimated total: ${monthlyTotal.toStringAsFixed(2)} $currency',
      ratesMissing
          ? 'Annual estimated total: unavailable (missing rate)'
          : 'Annual estimated total: ${(monthlyTotal * 12).toStringAsFixed(2)} $currency',
      'Service | Category | Amount | Currency | Monthly estimate',
      for (final item in sorted.take(37))
        '${item.name} | ${item.categoryName} | ${item.amount.toStringAsFixed(2)} | ${item.currency} | ${_convert(SubscriptionService.instance.monthlyEquivalent(item), item.currency, currency)?.toStringAsFixed(2) ?? 'Unavailable'}',
    ];
    final result = await FilePicker.saveFile(
      fileName: 'subtrack-report.pdf',
      mimeType: 'application/pdf',
      bytes: _makePdf(lines),
    );
    return result != null;
  }

  double? _convert(double amount, String from, String to) =>
      CurrencyService.instance.convert(amount, from: from, to: to);
  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  Uint8List _makePdf(List<String> lines) {
    final stream = StringBuffer('BT\n/F1 16 Tf\n48 790 Td\n');
    for (var i = 0; i < lines.length; i++) {
      if (i == 1) stream.write('/F1 10 Tf\n');
      if (i > 0) stream.write('0 -18 Td\n');
      final safe = _ascii(
        lines[i],
      ).replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      stream.write('($safe) Tj\n');
    }
    stream.write('ET');
    final contents = stream.toString();
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
      '<< /Length ${ascii.encode(contents).length} >>\nstream\n$contents\nendstream',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];
    final pdf = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(ascii.encode(pdf.toString()).length);
      pdf.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final xref = ascii.encode(pdf.toString()).length;
    pdf.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
    for (final offset in offsets.skip(1)) {
      pdf.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    pdf.write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF',
    );
    return Uint8List.fromList(ascii.encode(pdf.toString()));
  }

  String _ascii(String input) {
    const replacements = <int, String>{
      0x131: 'i',
      0x130: 'I',
      0x15f: 's',
      0x15e: 'S',
      0x11f: 'g',
      0x11e: 'G',
      0xfc: 'u',
      0xdc: 'U',
      0xf6: 'o',
      0xd6: 'O',
      0xe7: 'c',
      0xc7: 'C',
      0x20ba: 'TRY',
      0x20ac: 'EUR',
      0xa3: 'GBP',
    };
    return String.fromCharCodes(
      input.runes.map(
        (rune) => rune < 128 ? rune : (replacements[rune] ?? '?').codeUnitAt(0),
      ),
    );
  }
}
