import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  final VoidCallback? onThemeToggle;
  final VoidCallback? onSearch;
  final bool isDark;

  const HeaderBar({super.key, this.onThemeToggle, this.onSearch, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text('New API',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), onPressed: onSearch, tooltip: '搜索'),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onThemeToggle,
            tooltip: isDark ? '浅色模式' : '深色模式',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
