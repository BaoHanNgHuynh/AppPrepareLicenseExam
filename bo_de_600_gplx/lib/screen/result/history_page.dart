import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bo_de_600_gplx/services/history_service.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_review.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _service = const HistoryService();

  List<ExamHistoryItem> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _history = [];
          _loading = false;
          _error = 'Không có dữ liệu.';
        });
        return;
      }

      final items = await _service.fetchExamHistory(token: token);

      setState(() {
        _history = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(bool passed) => passed ? Colors.green : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm đề thi thử'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _history.isEmpty
                  ? const Center(child: Text('Chưa có kết quả nào.'))
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final percent = item.percent.toStringAsFixed(1);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                item.passed ? Icons.check_circle : Icons.cancel,
                                color: _statusColor(item.passed),
                              ),
                              title: Text(
                                '${item.examName} '
                                '- ${item.correct}/${item.totalQuestion} đúng '
                                '- $percent%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Sai câu điểm liệt: '
                                      '${item.diemLietWrong}'),
                                  Text('Thời gian làm: ${item.time} giây'),
                                  Text(
                                    'Lúc: ${_formatDate(item.created.toLocal())}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () {
                                final questions = item.questionsJson
                                    .map<Question>((e) => Question.fromJson(
                                        e as Map<String, dynamic>))
                                    .toList();

                                final selections =
                                    item.selectionsJson.map<int?>((e) {
                                  if (e == null) return null;
                                  if (e is int) return e;
                                  if (e is num) return e.toInt();
                                  return int.tryParse(e.toString());
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExamReviewPage(
                                      examName: item.examName,
                                      questions: questions,
                                      selections: selections,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
