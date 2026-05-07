import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

// ── 操练场 / API 调试页 ─────────────────────────────────
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final _client = ApiClient();
  final _msgCtrl = TextEditingController();
  final _systemCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];

  // Model
  List<String> _models = [];
  String _selectedModel = 'gpt-3.5-turbo';

  // Parameters
  double _temperature = 0.7;
  int _maxTokens = 2048;
  double _topP = 1.0;
  double _frequencyPenalty = 0;
  double _presencePenalty = 0;
  bool _stream = true;

  // Custom body
  bool _customMode = false;
  final _customBodyCtrl = TextEditingController();

  // SSE
  bool _sending = false;
  CancelToken? _cancelToken;

  // State
  bool _showSettings = false;
  bool _showDebug = false;
  String _lastRequest = '';
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _systemCtrl.dispose();
    _customBodyCtrl.dispose();
    _scrollCtrl.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _loadModels() async {
    try {
      final res = await _client.dio.get('/api/models');
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        final allModels = <String>[];
        data.forEach((_, v) {
          if (v is List) allModels.addAll(v.cast<String>());
        });
        if (allModels.isNotEmpty) setState(() { _models = allModels; _selectedModel = allModels.contains(_selectedModel) ? _selectedModel : allModels.first; });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() { _sending = true; _lastRequest = ''; _lastResponse = ''; });

    final userMsg = ChatMessage(role: 'user', content: text);
    final assistantMsg = ChatMessage(role: 'assistant', content: '', loading: true);
    setState(() { _messages.addAll([userMsg, assistantMsg]); });
    _scrollDown();

    try {
      if (_customMode) {
        await _sendCustom(text, assistantMsg);
      } else {
        await _sendStandard(text, assistantMsg);
      }
    } catch (e) {
      setState(() {
        assistantMsg.content = '请求失败: $e';
        assistantMsg.loading = false;
      });
    } finally {
      setState(() { _sending = false; });
    }
  }

  Map<String, dynamic> _buildPayload(String text) {
    final msgList = <Map<String, dynamic>>[];
    if (_systemCtrl.text.isNotEmpty) {
      msgList.add({'role': 'system', 'content': _systemCtrl.text});
    }
    // 历史消息
    for (final m in _messages.where((m) => m.role != 'assistant' || !m.loading)) {
      msgList.add({'role': m.role, 'content': m.content});
    }
    msgList.add({'role': 'user', 'content': text});

    return {
      'model': _selectedModel.isNotEmpty ? _selectedModel : 'gpt-3.5-turbo',
      'messages': msgList,
      'temperature': _temperature,
      'max_tokens': _maxTokens,
      'top_p': _topP,
      'frequency_penalty': _frequencyPenalty,
      'presence_penalty': _presencePenalty,
      'stream': _stream,
    };
  }

  Future<void> _sendStandard(String text, ChatMessage assistantMsg) async {
    final payload = _buildPayload(text);
    setState(() { _lastRequest = const JsonEncoder.withIndent('  ').convert(payload); });

    _cancelToken = CancelToken();
    final resp = await _client.dio.post(
      '/v1/chat/completions',
      data: payload,
      options: Options(
        responseType: _stream ? ResponseType.stream : ResponseType.json,
        headers: {'Accept': _stream ? 'text/event-stream' : 'application/json'},
      ),
      cancelToken: _cancelToken,
    );

    if (_stream) {
      final stream = resp.data.stream as Stream<List<int>>;
      var buffer = StringBuffer();
      String fullContent = '';
      String fullRaw = '';

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        fullRaw += text;
        buffer.write(text);

        // SSE 解析
        while (buffer.toString().contains('\n')) {
          final idx = buffer.toString().indexOf('\n');
          final line = buffer.toString().substring(0, idx).trim();
          buffer = StringBuffer(buffer.toString().substring(idx + 1));

          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            try {
              final json = jsonDecode(data);
              final choice = json['choices']?[0];
              final delta = choice?['delta'];
              if (delta != null && delta['content'] != null) {
                fullContent += delta['content'];
                if (mounted) {
                  setState(() {
                    assistantMsg.content = fullContent;
                  });
                  _scrollDown();
                }
              }
            } catch (_) {}
          }
        }
      }
      setState(() { _lastResponse = fullRaw; assistantMsg.loading = false; });
    } else {
      // 非流式
      final data = resp.data;
      final content = data['choices']?[0]?['message']?['content'] ?? '';
      setState(() {
        assistantMsg.content = content;
        assistantMsg.loading = false;
        _lastResponse = const JsonEncoder.withIndent('  ').convert(data);
      });
    }
  }

  Future<void> _sendCustom(String text, ChatMessage assistantMsg) async {
    try {
      final customPayload = jsonDecode(_customBodyCtrl.text);
      setState(() { _lastRequest = const JsonEncoder.withIndent('  ').convert(customPayload); });
      _cancelToken = CancelToken();

      final resp = await _client.dio.post(
        '/v1/chat/completions',
        data: customPayload,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
        cancelToken: _cancelToken,
      );

      final stream = resp.data.stream as Stream<List<int>>;
      var buffer = StringBuffer();
      String fullContent = '';
      String fullRaw = '';

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        fullRaw += text;
        buffer.write(text);

        while (buffer.toString().contains('\n')) {
          final idx = buffer.toString().indexOf('\n');
          final line = buffer.toString().substring(0, idx).trim();
          buffer = StringBuffer(buffer.toString().substring(idx + 1));
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              if (delta?['content'] != null) {
                fullContent += delta['content'];
                if (mounted) setState(() { assistantMsg.content = fullContent; });
                _scrollDown();
              }
            } catch (_) {}
          }
        }
      }
      setState(() { _lastResponse = fullRaw; assistantMsg.loading = false; });
    } on FormatException {
      setState(() { assistantMsg.content = 'JSON 格式错误'; assistantMsg.loading = false; });
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _stop() {
    _cancelToken?.cancel();
    if (_messages.any((m) => m.loading)) {
      setState(() {
        final last = _messages.lastWhere((m) => m.loading);
        last.loading = false;
        last.content = '[已停止]';
        _sending = false;
      });
    }
  }

  void _clear() {
    setState(() { _messages.clear(); _lastRequest = ''; _lastResponse = ''; });
  }

  // ── Settings Panel ──
  Widget _buildSettings() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView(
        children: [
          // Model selector
          DropdownButtonFormField<String>(
            initialValue: _selectedModel,
            decoration: const InputDecoration(labelText: '模型', isDense: true),
            items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedModel = v ?? _selectedModel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _systemCtrl,
            decoration: const InputDecoration(labelText: 'System Prompt', isDense: true, helperText: '可选，设定 AI 角色'),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text('Temperature: ${_temperature.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
          Slider(value: _temperature, min: 0, max: 2, onChanged: (v) => setState(() => _temperature = v)),
          Text('Max Tokens: $_maxTokens', style: const TextStyle(fontSize: 12)),
          Slider(value: _maxTokens.toDouble(), min: 1, max: 16384, divisions: 15, onChanged: (v) => setState(() => _maxTokens = v.round())),
          Text('Top P: ${_topP.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
          Slider(value: _topP, min: 0, max: 1, onChanged: (v) => setState(() => _topP = v)),
          const SizedBox(height: 8),
          SwitchListTile(title: const Text('流式输出', style: TextStyle(fontSize: 13)), value: _stream, dense: true, onChanged: (v) => setState(() => _stream = v)),
          SwitchListTile(title: const Text('自定义请求体', style: TextStyle(fontSize: 13)), value: _customMode, dense: true, onChanged: (v) => setState(() => _customMode = v)),
          if (_customMode) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customBodyCtrl,
              decoration: const InputDecoration(labelText: '自定义 JSON 请求体', border: OutlineInputBorder()),
              maxLines: 8,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.cleaning_services, size: 18),
            label: const Text('重置参数'),
            onPressed: () => setState(() {
              _temperature = 0.7; _maxTokens = 2048; _topP = 1.0;
              _frequencyPenalty = 0; _presencePenalty = 0; _customMode = false;
            }),
          ),
        ],
      ),
    );
  }

  // ── Debug Panel ──
  Widget _buildDebugPanel() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Debug', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showDebug = false)),
          ]),
          const Divider(),
          const Text('Request:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: SingleChildScrollView(
                child: SelectableText(_lastRequest.isEmpty ? '发送后会显示...' : _lastRequest, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Response:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: SingleChildScrollView(
                child: SelectableText(_lastResponse.isEmpty ? '接收后会显示...' : _lastResponse, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操练场'),
        actions: [
          IconButton(icon: Icon(_showSettings ? Icons.settings : Icons.settings_outlined), tooltip: '参数面板', onPressed: () => setState(() => _showSettings = !_showSettings)),
          IconButton(icon: Icon(_showDebug ? Icons.bug_report : Icons.bug_report_outlined), tooltip: 'Debug', onPressed: () => setState(() => _showDebug = !_showDebug)),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: '清空对话', onPressed: _clear),
        ],
      ),
      body: Row(
        children: [
          if (_showSettings) _buildSettings(),
          Expanded(child: _buildChatArea()),
          if (_showDebug) _buildDebugPanel(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.smart_toy, size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
                  const SizedBox(height: 12),
                  Text('操练场 — 调试 API 请求', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('选择模型和参数，输入提示词开始测试', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  if (_customMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Chip(label: Text('自定义模式 — 直接输入 JSON', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary))),
                    ),
                ]),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildMessage(_messages[i]),
              ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(isUser ? Icons.person : Icons.smart_toy, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: msg.loading
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('思考中...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ])
                : msg.content.startsWith('{') && msg.content.endsWith('}')
                  ? SelectableText(msg.content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))
                  : MarkdownBody(data: msg.content, selectable: true, styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14), code: TextStyle(fontSize: 12, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                    )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              enabled: !_sending,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _customMode ? '输入 user message（自定义模式下）' : '输入消息...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          if (_sending)
            IconButton(icon: const Icon(Icons.stop_circle, color: Colors.red), onPressed: _stop, iconSize: 36)
          else
            IconButton.filled(icon: const Icon(Icons.send), onPressed: _send, iconSize: 20),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String role;
  String content;
  bool loading;
  ChatMessage({required this.role, required this.content, this.loading = false});
}
