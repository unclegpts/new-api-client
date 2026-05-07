import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

class ChatPage extends StatefulWidget {
  final String? chatId;
  const ChatPage({super.key, this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _client = ApiClient();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];

  List<String> _models = [];
  String _selectedModel = '';
  bool _sending = false;
  StreamSubscription? _sseSub;
  CancelToken? _cancelToken;

  // Parameters
  double _temperature = 0.7;
  int _maxTokens = 2048;

  @override
  void initState() {
    super.initState();
    _loadModels();
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
        setState(() {
          _models = allModels;
          if (_models.isNotEmpty) _selectedModel = _models.first;
        });
      }
    } catch (_) {
      // silently fail, models will be empty
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(ChatMessage(role: 'assistant', content: '', streaming: true));
      _sending = true;
    });

    _cancelToken = CancelToken();
    final assistIdx = _messages.length - 1;

    final payload = {
      'model': _selectedModel,
      'messages': _messages
          .where((m) => !m.streaming)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
      'stream': true,
      'temperature': _temperature,
      'max_tokens': _maxTokens,
    };

    try {
      final response = await _client.dio.post(
        '/v1/chat/completions',
        data: payload,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
        cancelToken: _cancelToken,
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      _sseSub = stream.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.startsWith('data: ') && line.length > 6) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') return;
              try {
                final json = jsonDecode(data);
                final delta = json['choices']?[0]?['delta']?['content'];
                if (delta != null && delta is String) {
                  setState(() {
                    _messages[assistIdx].content += delta;
                  });
                  _scrollToBottom();
                }
              } catch (_) {}
            }
          }
        },
        onError: (_) {
          setState(() {
            _messages[assistIdx].streaming = false;
            if (_messages[assistIdx].content.isEmpty) {
              _messages[assistIdx].content = '发送失败，请重试';
            }
            _sending = false;
          });
        },
        onDone: () {
          setState(() {
            _messages[assistIdx].streaming = false;
            _sending = false;
          });
        },
        cancelOnError: false,
      );
    } catch (e) {
      setState(() {
        _messages[assistIdx].streaming = false;
        _messages[assistIdx].content = '发送失败: $e';
        _sending = false;
      });
    }
  }

  void _stopStreaming() {
    _cancelToken?.cancel();
    _sseSub?.cancel();
    if (_messages.isNotEmpty && _messages.last.streaming) {
      setState(() {
        _messages.last.streaming = false;
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _cancelToken?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedModel.isNotEmpty ? _selectedModel : null,
            hint: const Text('选择模型'),
            items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() => _selectedModel = v ?? _selectedModel),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showSettings,
            tooltip: '参数设置',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmpty(theme) : _buildMessageList(theme),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('开始对话', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('输入消息与 $_selectedModel 对话', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, idx) {
        final msg = _messages[idx];
        final isUser = msg.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: isUser ? null : const Radius.circular(4),
              ),
            ),
            child: isUser
                ? Text(msg.content, style: const TextStyle(fontSize: 15))
                : MarkdownBody(
                    data: msg.content.isEmpty ? (msg.streaming ? '思考中...' : '') : msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15),
                      code: TextStyle(fontSize: 13, backgroundColor: theme.colorScheme.surfaceContainerHighest),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                  onPressed: _stopStreaming,
                  tooltip: '停止',
                )
              : IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                  tooltip: '发送',
                ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (ctx) {
        double temp = _temperature;
        int tokens = _maxTokens;
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('参数设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Temperature'),
                    Expanded(
                      child: Slider(value: temp, min: 0, max: 2, divisions: 20, label: temp.toStringAsFixed(1), onChanged: (v) => setDialog(() => temp = v)),
                    ),
                    Text(temp.toStringAsFixed(1)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Max Tokens'),
                    Expanded(
                      child: Slider(value: tokens.toDouble(), min: 256, max: 32768, divisions: 20, label: tokens.toString(), onChanged: (v) => setDialog(() => tokens = v.toInt())),
                    ),
                    Text('$tokens'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  setState(() { _temperature = temp; _maxTokens = tokens; });
                  Navigator.pop(ctx);
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
      },
    );
  }
}

class ChatMessage {
  final String role;
  String content;
  bool streaming;
  ChatMessage({required this.role, required this.content, this.streaming = false});
}
