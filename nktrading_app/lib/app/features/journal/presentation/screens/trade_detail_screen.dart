import 'package:flutter/material.dart';
import 'package:nktrading_app/l10n/app_localizations.dart'; // Import localization
import 'image_viewer_screen.dart'; // Import màn hình xem ảnh mới

class TradeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trade;

  const TradeDetailScreen({super.key, required this.trade});

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? l10n.noValue : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final beforeImageUrl = trade['before_image_url'];

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.details}: ${trade['symbol']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              l10n.symbolLabel,
              trade['symbol'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.directionLabel,
              trade['direction'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.entryPriceLabel,
              trade['entry_price']?.toString() ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.exitPriceLabel,
              trade['exit_price']?.toString() ?? l10n.notClosed,
            ),
            _buildDetailRow(
              context,
              l10n.quantityLabel,
              trade['quantity']?.toString() ?? 'N/A',
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              l10n.strategyLabel,
              trade['strategy'] ?? '',
            ),
            _buildDetailRow(context, l10n.notesLabel, trade['notes'] ?? ''),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              l10n.mindsetRatingLabel,
              trade['mindset_rating']?.toString() ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.emotionTagsLabel,
              (trade['emotion_tags'] as List<dynamic>?)?.join(', ') ?? '',
            ),

            if (beforeImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  l10n.chart,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

            if (beforeImageUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${l10n.chartScreenshot}:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      beforeImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.fullscreen),
                      label: Text(l10n.viewImage),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewerScreen(imageUrl: beforeImageUrl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
