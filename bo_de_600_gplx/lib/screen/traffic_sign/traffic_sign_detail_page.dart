import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/trafficSign.dart';
import 'package:bo_de_600_gplx/ui/tts_page.dart';

class TrafficSignDetailPage extends StatefulWidget {
  final TrafficSign sign;
  const TrafficSignDetailPage({required this.sign, Key? key}) : super(key: key);

  @override
  State<TrafficSignDetailPage> createState() => _TrafficSignDetailPageState();
}

class _TrafficSignDetailPageState extends State<TrafficSignDetailPage> {
  TtsHelper? _tts;

  @override
  void initState() {
    super.initState();
    _tts = TtsHelper(onStateChanged: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sign;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.signId),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(s.imageUrl),
            const SizedBox(height: 16),

            // ✅ Tên biển + nút đọc
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                ),
                if (_tts != null)
                  _tts!.buildSpeakButton(
                    text: s.title,
                    key: 'title',
                    tooltip: 'Đọc tên biển',
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                      children: [
                        const TextSpan(
                          text: 'Ý nghĩa: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: s.description,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_tts != null)
                  _tts!.buildSpeakButton(
                    text: 'Ý nghĩa. ${s.description}',
                    key: 'desc',
                    tooltip: 'Đọc ý nghĩa',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
