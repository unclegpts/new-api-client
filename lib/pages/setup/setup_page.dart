import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _urlController = TextEditingController();
  final _client = ApiClient();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final url = await _client.getServerUrl();
    if (url != null) {
      _urlController.text = url;
    }
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = '请输入服务器地址');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _client.configure(baseUrl: url);
      // Test connection
      final response = await _client.dio.get('/api/status');
      if (response.data['success'] == true) {
        await _client.setServerUrl(url);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        setState(() => _error = '服务器返回错误');
      }
    } catch (e) {
      setState(() => _error = '无法连接到服务器，请检查地址');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('连接到 New API 服务器',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('请输入你的 new-api 实例地址',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'https://your-server.com',
                    prefixIcon: const Icon(Icons.link),
                    border: const OutlineInputBorder(),
                    errorText: _error,
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _connect(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _connect,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('连接'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
