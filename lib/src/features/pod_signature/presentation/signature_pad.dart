import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.onSaved,
    this.savedMessage = 'Signature exported as PNG base64.',
  });

  final FutureOr<void> Function(String)? onSaved;
  final String savedMessage;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  Size _paintSize = Size.zero;
  bool _saving = false;

  void _beginStroke(Offset position) {
    setState(() => _strokes.add([position]));
  }

  void _continueStroke(Offset position) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(position));
  }

  Future<String> exportPngBase64() async {
    if (_strokes.isEmpty || _paintSize.isEmpty) {
      throw StateError('Draw a signature before saving.');
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final sourceSize = _paintSize;
    const size = Size(800, 400);
    canvas.scale(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    canvas.drawRect(Offset.zero & sourceSize, Paint()..color = Colors.white);
    SignaturePainter(strokes: _strokes).paint(canvas, sourceSize);
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Unable to encode the signature image.');
    return base64Encode(data.buffer.asUint8List());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final base64Png = await exportPngBase64();
      await widget.onSaved?.call(base64Png);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.savedMessage)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save signature: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _paintSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) => _beginStroke(details.localPosition),
                onPanUpdate: (details) =>
                    _continueStroke(details.localPosition),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: SignaturePainter(strokes: _strokes),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _strokes.isEmpty || _saving
                  ? null
                  : () => setState(_strokes.clear),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _strokes.isEmpty || _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save signature'),
            ),
          ],
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  const SignaturePainter({required this.strokes});

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.single,
          1.5,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
      } else if (stroke.length > 1) {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (final point in stroke.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
