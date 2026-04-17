import 'dart:ui';
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

  ({IconData icon, Color color, String label, String description}) _analyzeSafety() {
    final content = widget.content.toLowerCase();
    
    if (widget.resultType != 'url') {
      return (
        icon: Icons.verified_user_outlined,
        color: AppTheme.accent,
        label: 'Verified Format',
        description: 'This ${widget.resultType} format follows standard structures.',
      );
    }

    if (content.startsWith('https://')) {
      // Check for common shorteners
      final shorteners = ['bit.ly', 't.co', 'goo.gl', 'tinyurl.com', 'is.gd', 'buff.ly', 'rebrand.ly'];
      if (shorteners.any((s) => content.contains(s))) {
        return (
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          label: 'URL Masked',
          description: 'This is a shortened URL. The actual destination is hidden.',
        );
      }
      return (
        icon: Icons.security,
        color: Colors.greenAccent,
        label: 'Secure Link',
        description: 'This link uses modern encryption (HTTPS).',
      );
    }

    if (content.startsWith('http://')) {
      return (
        icon: Icons.gpp_maybe_rounded,
        color: Colors.redAccent,
        label: 'Insecure Link',
        description: 'Caution: This site uses unencrypted HTTP protocol.',
      );
    }

    return (
      icon: Icons.help_outline,
      color: Colors.grey,
      label: 'Unknown',
      description: 'Unable to verify the safety profile of this content.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final scan = provider.history.firstWhere((s) => s.content == widget.content, orElse: () => ScanHistory(
      content: widget.content, type: widget.type, resultType: widget.resultType, scannedAt: DateTime.now()
    ));

    final safety = _analyzeSafety();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2), width: 1.5),
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
          const SizedBox(height: 16),
          // Smart Analysis Shield
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: safety.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: safety.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(safety.icon, color: safety.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Analysis: ${safety.label}',
                        style: TextStyle(color: safety.color, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        safety.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
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
    ),
    ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HistoryProvider provider) {

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
            if (widget.resultType == 'payment')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(widget.content),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Pay Now'),
                ),
              ),
            if (widget.resultType == 'event')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL('https://www.google.com/calendar/render?action=TEMPLATE&text=Scanned%20Event&details=${Uri.encodeComponent(widget.content)}'),
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: const Text('Add to Schedule'),
                ),
              ),
            if (widget.resultType == 'wifi')
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
                  icon: const Icon(Icons.wifi_rounded),
                  label: const Text('Connect WiFi'),
                ),
              ),
            if (widget.resultType == 'text' || widget.resultType == 'email')
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
