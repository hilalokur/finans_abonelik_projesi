// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/receipt_ocr_service.dart';
import '../../services/bank_transaction_analyzer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import 'add_subscription_screen.dart';

enum _ImageChoice { camera, gallery, files }

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _picker = ImagePicker();
  final _serviceController = TextEditingController();
  final _amountController = TextEditingController();
  ReceiptOcrResult? _result;
  DateTime? _transactionDate;
  bool _processing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serviceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final choice = await showModalBottomSheet<_ImageChoice>(
        context: context,
        backgroundColor: AppColors.surfaceSolid,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryLight,
                ),
                title: const Text('Kamerayla çek'),
                onTap: () => Navigator.pop(context, _ImageChoice.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryLight,
                ),
                title: const Text('Galeriden seç'),
                onTap: () => Navigator.pop(context, _ImageChoice.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.folder_open_rounded,
                  color: AppColors.primaryLight,
                ),
                title: const Text('Dosyalardan seç'),
                onTap: () => Navigator.pop(context, _ImageChoice.files),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == _ImageChoice.files) {
        final picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['png', 'jpg', 'jpeg'],
        );
        if (picked.isEmpty || picked.first.path == null) {
          return;
        }
        await _scan(picked.first.path!);
        return;
      }
      final image = await _picker.pickImage(
        source: choice == _ImageChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 90,
      );
      if (image != null) await _scan(image.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Kamera veya görsel seçici açılamadı.');
    }
  }

  Future<void> _analyzeBankCsv() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (file == null) return;
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      final candidates = const BankTransactionAnalyzer().analyzeCsv(text);
      if (!mounted) return;
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Düzenli aylık ödeme adayı bulunamadı.'),
          ),
        );
        return;
      }
      final candidate = await showDialog<RecurringPaymentCandidate>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Olası abonelik ödemeleri'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in candidates)
                  ListTile(
                    title: Text(item.merchant),
                    subtitle: Text(
                      '${item.occurrences} işlem · ortalama ${item.averageAmount.toStringAsFixed(2)} ${item.currency}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => Navigator.pop(context, item),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Şimdilik geç'),
            ),
          ],
        ),
      );
      if (candidate == null || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddSubscriptionScreen(
            initialServiceName: candidate.merchant,
            initialAmount: candidate.averageAmount,
            initialCurrency: candidate.currency,
            initialRenewalDate: candidate.lastDate.add(
              const Duration(days: 30),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banka CSV dosyası okunamadı.')),
        );
      }
    }
  }

  Future<void> _scan(String path) async {
    setState(() {
      _processing = true;
      _errorMessage = null;
      _result = null;
    });
    try {
      final result = await ReceiptOcrService.instance.scanImage(path);
      if (!mounted) return;
      _serviceController.text = result.serviceName ?? '';
      _amountController.text = result.amount?.toStringAsFixed(2) ?? '';
      setState(() {
        _result = result;
        _transactionDate = result.transactionDate;
        _processing = false;
        if (result.text.trim().isEmpty) {
          _errorMessage =
              'Görselden metin okunamadı. Daha net bir fotoğraf deneyebilirsin.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage =
            'Belge okunamadı. Görsel biçimini ve netliğini kontrol et.';
      });
    }
  }

  Future<void> _reviewAndContinue() async {
    final result = _result;
    if (result == null) return;
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    final serviceName = _serviceController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgileri kontrol et'),
        content: Text(
          'Servis: ${serviceName.isEmpty ? 'Tespit edilmedi' : serviceName}\nTutar: ${amount?.toStringAsFixed(2) ?? 'Tespit edilmedi'} ${result.currency}\nİşlem tarihi: ${_formatDate(_transactionDate) ?? 'Tespit edilmedi'}\n\nBu bilgiler abonelik formuna aktarılacak. Kaydetmeden önce düzenleyebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Geri dön'),
          ),
          AppGradientButton(
            width: 140,
            height: 42,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Formu aç'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final renewalDate =
        _transactionDate != null && _transactionDate!.isAfter(DateTime.now())
        ? _transactionDate!
        : DateTime.now().add(const Duration(days: 30));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSubscriptionScreen(
          initialServiceName: serviceName.isEmpty ? null : serviceName,
          initialAmount: amount,
          initialCurrency: result.currency,
          initialRenewalDate: renewalDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OCR / Belge Tara')),
    body: AppBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            const Text(
              'Belgeden abonelik bilgisi çıkar',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Fotoğraf çek veya galerinden bir ödeme belgesi seç. Bulunan bilgiler kaydedilmeden önce sana gösterilir.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(20),
              radius: 26,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Fatura veya ödeme belgesi',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'PNG, JPG ve JPEG görselleri desteklenir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  AppGradientButton(
                    onPressed: _processing ? null : _chooseImage,
                    isLoading: _processing,
                    child: const Text(
                      'Belge Seç / Fotoğraf Çek',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              onPressed: _analyzeBankCsv,
              child: const Text('Banka hareketlerini analiz et (CSV)'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              AppCard(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.lavender),
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Bulunan bilgiler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _serviceController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Servis adı',
                        prefixIcon: Icon(Icons.subscriptions_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tutar (${_result!.currency})',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 19,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'İşlem tarihi: ${_formatDate(_transactionDate) ?? 'Bulunamadı'}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppGradientButton(
                      onPressed: _reviewAndContinue,
                      child: const Text('Bilgileri Onayla ve Forma Aktar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Tanınan metni göster'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _result!.text,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  String? _formatDate(DateTime? date) => date == null
      ? null
      : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
