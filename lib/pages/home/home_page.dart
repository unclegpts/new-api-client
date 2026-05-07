import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.api, size: 72, color: color.primary),
                    const SizedBox(height: 16),
                    Text('New API', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('下一代 AI 模型网关', style: theme.textTheme.titleMedium?.copyWith(color: color.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('统一管理和分发多种 LLM，支持 OpenAI / Claude / Gemini 格式互转',
                        style: theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('登录'),
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text('配置服务器'),
                          onPressed: () => context.go('/setup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Feature highlights
          Container(
            padding: const EdgeInsets.all(24),
            color: color.surfaceContainerLow,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _FeatureChip(Icons.swap_horiz, '格式互转'),
                _FeatureChip(Icons.speed, '流式对话'),
                _FeatureChip(Icons.groups, '多用户管理'),
                _FeatureChip(Icons.payments, '计费系统'),
                _FeatureChip(Icons.security, '权限控制'),
                _FeatureChip(Icons.smart_toy, '40+ 提供商'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
