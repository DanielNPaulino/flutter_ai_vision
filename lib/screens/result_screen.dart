import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for Clipboard
import 'package:url_launcher/url_launcher.dart'; // add url_launcher in pubspec
import 'package:hive/hive.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final String commonName;
  final String scientificName;
  final double confidence;
  final String description;
  final String habitat;
  final String diet;
  final String conservationStatus;
  final String? birdImageUrl;
  final String? localImagePath;
  final String size;
  final String weight;

  const ResultScreen({
    Key? key,
    required this.image,
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    required this.description,
    required this.habitat,
    required this.diet,
    required this.conservationStatus,
    this.birdImageUrl,
    this.localImagePath,
    required this.size,
    required this.weight,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final Box favoritesBox;
  late final Box notesBox;
  bool _isFavorite = false;
  late TextEditingController _notesController;
  bool _notesChanged = false;

  String get birdId => widget.scientificName; // Use scientific name as unique ID

  @override
  void initState() {
    super.initState();
    favoritesBox = Hive.box('favorites');
    notesBox = Hive.box('notes');
    _isFavorite = favoritesBox.get(birdId, defaultValue: false);
    _notesController = TextEditingController(text: notesBox.get(birdId, defaultValue: ''));
    _notesController.addListener(() {
      setState(() {
        _notesChanged = true;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      favoritesBox.put(birdId, _isFavorite);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites')),
    );
  }

  void _saveNote() {
    notesBox.put(birdId, _notesController.text);
    setState(() {
      _notesChanged = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved!')),
    );
  }

  void _deleteNote() {
    notesBox.delete(birdId);
    _notesController.text = '';
    setState(() {
      _notesChanged = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted!')),
    );
  }

  // pick the best available image: localImagePath -> birdImageUrl -> widget.image -> placeholder
  Widget _buildTopImage() {
    if (widget.localImagePath != null && widget.localImagePath!.isNotEmpty) {
      return Image.file(File(widget.localImagePath!), fit: BoxFit.cover);
    } else if (widget.birdImageUrl != null && widget.birdImageUrl!.isNotEmpty) {
      return Image.network(
        widget.birdImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        (progress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, st) => _placeholderImage(),
      );
    } else if (widget.image.path.isNotEmpty) {
      return Image.file(widget.image, fit: BoxFit.cover);
    } else {
      return _placeholderImage();
    }
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.photo, size: 72, color: Colors.grey),
      ),
    );
  }

  // map conservation status to badge color
  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('crit') || s.contains('critical'))
      return Colors.red.shade700;
    if (s.contains('endang')) return Colors.deepOrange;
    if (s.contains('vulner')) return Colors.orange;
    if (s.contains('near')) return Colors.amber;
    if (s.contains('least') || s.contains('lc')) return Colors.green;
    return Colors.grey;
  }

  // open wikipedia page for scientific name (fallback to search)
  Future<void> _openWikipedia() async {
    final query = widget.scientificName.isNotEmpty
        ? widget.scientificName
        : widget.commonName;
    final encoded = Uri.encodeComponent(query.replaceAll(' ', '_'));
    final url = Uri.parse('https://en.wikipedia.org/wiki/$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // try search
      final search = Uri.parse(
        'https://en.wikipedia.org/w/index.php?search=${Uri.encodeComponent(query)}',
      );
      if (await canLaunchUrl(search)) {
        await launchUrl(search, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open Wikipedia on this device.'),
          ),
        );
      }
    }
  }

  // basic share fallback: copy key info to clipboard (you can replace with share_plus)
  Future<void> _onShare() async {
    final text =
        '${widget.commonName} (${widget.scientificName})\nConfidence: ${(widget.confidence * 100).toStringAsFixed(1)}%\nLearn more: https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.scientificName.replaceAll(' ', '_'))}';
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bird info copied to clipboard (use share_plus for full share).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.conservationStatus);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Floating buttons for actions
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              final msg = _isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
            },
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            label: const Text('Favorite'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Top image section
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildTopImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.commonName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.scientificName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBar is now below the image
            Material(
              color: theme.scaffoldBackgroundColor,
              child: TabBar(
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Details'),
                ],
              ),
            ),
            // Expanded TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  // ---------- Overview Tab ----------
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      80,
                    ), // extra bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Confidence animated bar + percent
                        Text(
                          'AI Confidence',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: widget.confidence.clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, value, child) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey[300],
                                color: value > 0.75
                                    ? Colors.green
                                    : (value > 0.4
                                          ? Colors.orange
                                          : Colors.red),
                                minHeight: 12,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(value * 100).toStringAsFixed(1)}% confidence',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick stats row (badges)
                        Row(
                          children: [
                            _statBadge(Icons.height, 'Size', widget.size),
                            const SizedBox(width: 8),
                            _statBadge(
                              Icons.fitness_center,
                              'Weight',
                              widget.weight,
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(
                              widget.conservationStatus,
                              statusColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Description card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.description.isNotEmpty
                                      ? widget.description
                                      : 'No description available.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Habitat & Diet inline
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.park),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Habitat',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.habitat.isNotEmpty
                                      ? widget.habitat
                                      : 'Unknown habitat',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.restaurant),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Diet',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.diet.isNotEmpty
                                      ? widget.diet
                                      : 'Unknown diet',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _openWikipedia,
                              icon: const Icon(Icons.language),
                              label: const Text('Wikipedia'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _onShare,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ---------- Details Tab ----------
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(
                          Icons.info_outline,
                          'Common Name',
                          widget.commonName,
                        ),
                        _detailRow(
                          Icons.science,
                          'Scientific Name',
                          widget.scientificName,
                        ),
                        _detailRow(
                          Icons.calendar_today,
                          'Identified',
                          widget.size,
                        ),
                        _detailRow(
                          Icons.bar_chart,
                          'Confidence',
                          '${(widget.confidence * 100).toStringAsFixed(1)}%',
                        ),
                        _detailRow(
                          Icons.eco,
                          'Conservation',
                          widget.conservationStatus,
                        ),
                        _detailRow(Icons.park, 'Habitat', widget.habitat),
                        _detailRow(Icons.restaurant, 'Diet', widget.diet),
                        _detailRow(Icons.scale, 'Weight', widget.weight),
                        _detailRow(Icons.straighten, 'Size', widget.size),
                        const SizedBox(height: 20),
                        // Large description card if needed
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap the star to add to favorites. Use Share to quickly copy details.',
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.red),
                                      onPressed: _toggleFavorite,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        _isFavorite
                                            ? "Favorited"
                                            : "Not Favorited"),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text("Your Notes:",
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText:
                                        "Add your personal note about this bird...",
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          _notesChanged ? _saveNote : null,
                                      child: const Text("Save Note"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _notesController.text.isNotEmpty
                                          ? _deleteNote
                                          : null,
                                      child: const Text("Delete Note"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : 'Unknown'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
