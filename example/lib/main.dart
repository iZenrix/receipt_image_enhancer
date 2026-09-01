import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';

void main() {
  runApp(const ReceiptEnhancerExampleApp());
}

class ReceiptEnhancerExampleApp extends StatelessWidget {
  const ReceiptEnhancerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Image Enhancer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4B3A)),
        useMaterial3: true,
      ),
      home: const EnhancePage(),
    );
  }
}

class EnhancePage extends StatefulWidget {
  const EnhancePage({super.key});

  @override
  State<EnhancePage> createState() => _EnhancePageState();
}

class _EnhancePageState extends State<EnhancePage> {
  final _enhancer = const ReceiptImageEnhancer();
  final _picker = ImagePicker();

  Uint8List? _originalBytes;
  Uint8List? _enhancedBytes;
  ReceiptEnhancePreset _preset = ReceiptEnhancePreset.balanced;
  bool _autoCrop = true;
  bool _busy = false;
  String? _status;
  Duration? _duration;

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _originalBytes = bytes;
      _enhancedBytes = null;
      _status = 'Image selected (${bytes.length} bytes)';
      _duration = null;
    });
  }

  Future<void> _loadFixture() async {
    final data = await rootBundle.load('assets/synthetic_receipt.jpg');
    setState(() {
      _originalBytes = data.buffer.asUint8List();
      _enhancedBytes = null;
      _status = 'Loaded bundled synthetic fixture';
      _duration = null;
    });
  }

  Future<void> _enhance() async {
    final original = _originalBytes;
    if (original == null) {
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Enhancing...';
    });
    try {
      final result = await _enhancer.enhanceBytes(
        original,
        options: ReceiptEnhanceOptions(
          preset: _preset,
          autoCrop: _autoCrop,
          outputFormat: _preset == ReceiptEnhancePreset.scan
              ? ReceiptOutputFormat.png
              : ReceiptOutputFormat.jpeg,
        ),
      );
      setState(() {
        _enhancedBytes = result.bytes;
        _duration = result.processingDuration;
        _status =
            'Done ${result.width}x${result.height} crop=${result.cropApplied} '
            'warnings=${result.warnings.map((w) => w.name).join(",")}';
      });
    } on ReceiptImageEnhancerException catch (error) {
      setState(() => _status = 'Error ${error.code.name}: ${error.message}');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _openFullscreen({required String title, required Uint8List bytes}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerPage(title: title, bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Image Enhancer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : _pick,
                child: const Text('Pick image'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _loadFixture,
                child: const Text('Load fixture'),
              ),
              FilledButton.tonal(
                onPressed: _busy || _originalBytes == null ? null : _enhance,
                child: const Text('Enhance'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Preset', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: ReceiptEnhancePreset.values.map((preset) {
              return ChoiceChip(
                label: Text(preset.name),
                selected: _preset == preset,
                onSelected: _busy
                    ? null
                    : (_) => setState(() => _preset = preset),
              );
            }).toList(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto crop'),
            value: _autoCrop,
            onChanged: _busy
                ? null
                : (value) => setState(() => _autoCrop = value),
          ),
          if (_status != null) Text(_status!),
          if (_duration != null)
            Text('Processing: ${_duration!.inMilliseconds} ms'),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_originalBytes != null) ...[
            const SizedBox(height: 8),
            _ImagePreviewCard(
              label: 'Original',
              bytes: _originalBytes!,
              onTap: () =>
                  _openFullscreen(title: 'Original', bytes: _originalBytes!),
            ),
          ],
          if (_enhancedBytes != null) ...[
            const SizedBox(height: 16),
            _ImagePreviewCard(
              label: 'Enhanced',
              bytes: _enhancedBytes!,
              onTap: () =>
                  _openFullscreen(title: 'Enhanced', bytes: _enhancedBytes!),
            ),
          ],
          if (!Platform.isAndroid && !Platform.isIOS)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Primary targets are Android and iOS. Desktop may work for '
                'local demos when OpenCV is available to the build hook.',
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.label,
    required this.bytes,
    required this.onTap,
  });

  final String label;
  final Uint8List bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              'Tap to enlarge',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen viewer with pinch-zoom and pan.
class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({super.key, required this.title, required this.bytes});

  final String title;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 8,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
