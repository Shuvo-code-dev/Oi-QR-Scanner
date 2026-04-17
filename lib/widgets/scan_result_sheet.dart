import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import '../theme/app_theme.dart';
import '../providers/history_provider.dart';
import '../models/scan_history_model.dart';
import './ad_banner_widget.dart';

class ScanResultSheet extends StatefulWidget {
  final String content;
  final String type;
  final String resultType;

  const ScanResultSheet({
    super.key,
    required this.content,
    required this.type,
    required this.resultType,
  });

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  String? _translatedText;
  bool _isTranslating = false;

  Future<void> _translateText(String sourceText) async {
    setState(() => _isTranslating = true);
    try {
      final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages = await languageIdentifier.identifyPossibleLanguages(sourceText);
      await languageIdentifier.close();

      String sourceLanguage = TranslateLanguage.english.bcpCode;
      if (possibleLanguages.isNotEmpty) {
        sourceLanguage = possibleLanguages.first.languageTag;
      }

      final onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.values.firstWhere((e) => e.bcpCode == sourceLanguage, orElse: () => TranslateLanguage.english),
        targetLanguage: TranslateLanguage.bengali,
      );

      final response = await onDeviceTranslator.translateText(sourceText);
      await onDeviceTranslator.close();
      
      if (mounted) {
        setState(() {
          _translatedText = response;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final scan = provider.history.firstWhere((s) => s.content == widget.content, orElse: () => ScanHistory(
      content: widget.content, type: widget.type, resultType: widget.resultType, scannedAt: DateTime.now()
    ));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scan Result',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => provider.toggleFavorite(scan),
                    icon: Icon(
                      scan.isFavorite ? Icons.star : Icons.star_border,
                      color: scan.isFavorite ? Colors.amber : Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.content,
                  style: const TextStyle(fontSize: 16),
                ),
                if (_translatedText != null) ...[
                  const Divider(height: 24, color: Colors.white10),
                  const Text('Translation (Bengali):', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                  const SizedBox(height: 4),
                  Text(_translatedText!, style: const TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context, provider),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          const AdBannerWidget(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HistoryProvider provider) {
    bool isWiFi = widget.content.startsWith('WIFI:');

    return Column(
      children: [
        Row(
          children: [
            if (widget.resultType == 'url')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(widget.content),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open'),
                ),
              ),
            if (widget.resultType == 'phone')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL('tel:${widget.content}'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
            if (isWiFi)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final success = await provider.connectToWiFi(widget.content);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Connected to WiFi' : 'Failed to connect')),
                      );
                    }
                  },
                  icon: const Icon(Icons.wifi),
                  label: const Text('Connect WiFi'),
                ),
              ),
            if (!isWiFi && (widget.resultType == 'text' || widget.resultType == 'email'))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context, widget.content),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Share.share(_translatedText ?? widget.content),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (widget.type == 'ocr') ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTranslating ? null : () => _translateText(widget.content),
                  icon: _isTranslating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.translate),
                  label: const Text('Translate'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await _canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<bool> _canLaunchUrl(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
