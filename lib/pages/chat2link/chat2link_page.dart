import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

// ── 对话分享 — Chat2Link ─────────────────────────────────
class Chat2LinkPage extends StatefulWidget {
  const Chat2LinkPage({super.key});

  @override
  State<Chat2LinkPage> createState() => _Chat2LinkPageState();
}

class _Chat2LinkPageState extends State<Chat2LinkPage> {
  final _client = ApiClient();
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  String? _shareUrl;
  String? _error;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _createLink() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() { _loading = true; _error = null; _shareUrl = null; });
    try {
      final res = await _client.dio.post('/api/chat2link/', data: {
        'content': text,
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': text},
        ],
      });
      if (res.data['success'] == true && mounted) {
        setState(() {
          _shareUrl = res.data['data']?['url'] ?? res.data['data']?.toString();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '创建失败'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对话分享')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.share, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('分享对话', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('创建可分享的对话链接，他人可查看完整对话内容',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 20),
              TextField(
                controller: _msgCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '对话内容',
                  hintText: '输入要分享的对话文本...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.link),
                  label: const Text('生成分享链接'),
                  onPressed: _loading ? null : _createLink,
                ),
              ),
              if (_shareUrl != null) ...[
                const SizedBox(height: 20),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      const Row(children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('链接已生成', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ]),
                      const SizedBox(height: 8),
                      SelectableText(_shareUrl!, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制链接'),
                        onPressed: () {
                          // Copy to clipboard
                        },
                      ),
                    ]),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
