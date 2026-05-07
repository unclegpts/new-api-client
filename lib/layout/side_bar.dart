import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

class SideBar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const SideBar({super.key, required this.collapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 64 : 240,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavGroup(context, l10n.t('nav_chat'), [
                  _NavItem(Icons.terminal, l10n.t('nav_playground'), '/console/playground'),
                  _NavItem(Icons.message, l10n.t('nav_chat'), '/console/chat'),
                ]),
                const Divider(height: 1),
                _buildNavGroup(context, l10n.t('nav_dashboard'), [
                  _NavItem(Icons.analytics, l10n.t('dashboard_title'), '/console'),
                  _NavItem(Icons.vpn_key, l10n.t('nav_token'), '/console/token'),
                  _NavItem(Icons.history, l10n.t('nav_log'), '/console/log'),
                  _NavItem(Icons.image, l10n.t('nav_midjourney'), '/console/midjourney'),
                  _NavItem(Icons.task, l10n.t('nav_task'), '/console/task'),
                ]),
                const Divider(height: 1),
                _buildNavGroup(context, l10n.t('nav_personal'), [
                  _NavItem(Icons.wallet, l10n.t('nav_topup'), '/console/topup'),
                  _NavItem(Icons.settings, l10n.t('nav_settings'), '/console/personal'),
                ]),
                const Divider(height: 1),
                _buildNavGroup(context, l10n.t('nav_channel'), [
                  _NavItem(Icons.cable, l10n.t('nav_channel'), '/console/channel'),
                  _NavItem(Icons.subscriptions, l10n.t('nav_subscription'), '/console/subscription'),
                  _NavItem(Icons.model_training, l10n.t('nav_models'), '/console/models'),
                  _NavItem(Icons.rocket_launch, l10n.t('nav_deployment'), '/console/deployment'),
                  _NavItem(Icons.card_giftcard, l10n.t('nav_redemption'), '/console/redemption'),
                  _NavItem(Icons.people, l10n.t('nav_user_admin'), '/console/user_admin'),
                  _NavItem(Icons.tune, l10n.t('nav_system_setting'), '/console/setting'),
                ]),
              ],
            ),
          ),
          InkWell(
            onTap: onToggle,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child:
                  Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup(BuildContext context, String title, List<_NavItem> items) {
    if (collapsed) {
      return Column(
        children: items.map((item) => _buildCollapsedItem(context, item)).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ),
        ...items.map((item) => _buildExpandedItem(context, item)),
      ],
    );
  }

  Widget _buildExpandedItem(BuildContext context, _NavItem item) {
    return ListTile(
      dense: true,
      leading: Icon(item.icon, size: 20),
      title: Text(item.label, style: const TextStyle(fontSize: 14)),
      onTap: () => context.go(item.route),
    );
  }

  Widget _buildCollapsedItem(BuildContext context, _NavItem item) {
    return Tooltip(
      message: item.label,
      child: IconButton(
        icon: Icon(item.icon),
        onPressed: () => context.go(item.route),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}
