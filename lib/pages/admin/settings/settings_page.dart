import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

// ── 系统设置 — 6 大类完整配置 ───────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final _client = ApiClient();
  late TabController _tabCtrl;

  Map<String, dynamic> _options = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.get('/api/option/');
      if (res.data['success'] == true && mounted) {
        setState(() { _options = Map<String, dynamic>.from(res.data['data'] ?? {}); _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  Future<void> _save(String key, dynamic value) async {
    try {
      await _client.dio.post('/api/option/', data: {key: value});
      setState(() => _options[key] = value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red));
    }
  }

  dynamic _opt(String key) => _options[key];

  // ── UI helpers ──
  Widget _t(String label, String key, {int maxLines = 1, bool obscure = false, bool isNum = false}) {
    final ctrl = TextEditingController(text: (_opt(key) ?? '').toString());
    return _buildField(label, ctrl, (v) => _save(key, isNum ? num.tryParse(v) ?? v : v), maxLines: maxLines, obscure: obscure);
  }

  Widget _sw(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: _opt(key) == true || _opt(key)?.toString() == 'true',
      onChanged: (v) => _save(key, v),
      dense: true,
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, Function(String) onSave, {int maxLines = 1, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        IconButton(icon: const Icon(Icons.check, color: Colors.green, size: 20), onPressed: () => onSave(ctrl.text), tooltip: '保存', visualDensity: VisualDensity.compact),
      ]),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(children: [Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Text(title, style: Theme.of(context).textTheme.titleSmall)]),
          ),
          ...children,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: const TextStyle(color: Colors.red)), ElevatedButton(onPressed: _load, child: const Text('重试'))])));

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '运营'),
            Tab(text: '功能'),
            Tab(text: '模型'),
            Tab(text: '支付'),
            Tab(text: '限流'),
            Tab(text: '仪表盘'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOperation(),
          _buildFeatures(),
          _buildModels(),
          _buildPayment(),
          _buildRateLimit(),
          _buildDashboard(),
        ],
      ),
    );
  }

  // ═══════ 运营设置 ═══════
  Widget _buildOperation() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('基础信息', Icons.info_outline, [
        _t('系统名称', 'SystemName'),
        _t('Logo URL', 'LogoURL'),
        _t('服务器地址', 'ServerAddress'),
        _t('首页公告', 'Notice', maxLines: 3),
        _t('公告类型', 'NoticeType'),
      ]),
      _section('通知配置', Icons.notifications, [
        _t('Webhook 地址', 'WebHookURL'),
        _t('Webhook 密钥', 'WebHookSecret', obscure: true),
        _t('Bark URL', 'BarkURL'),
        _t('Gotify 地址', 'GotifyURL'),
        _t('Gotify Token', 'GotifyToken', obscure: true),
      ]),
      _section('监控与日志', Icons.monitor_heart, [
        _sw('启用监控', 'MonitoringEnabled'),
        _t('日志保留天数', 'LogRetentionDays', isNum: true),
        _t('Ping 间隔 (秒)', 'PingInterval', isNum: true),
      ]),
      _section('签到与信用', Icons.card_giftcard, [
        _sw('启用签到', 'CheckInEnabled'),
        _t('签到额度', 'CheckInQuota', isNum: true),
        _t('信用额度', 'CreditLimit', isNum: true),
      ]),
      _section('敏感词', Icons.block, [
        _t('敏感词列表 (逗号分隔)', 'SensitiveWords'),
      ]),
      _section('侧栏与导航', Icons.view_sidebar, [
        _sw('显示聊天模块', 'SidebarModulesAdmin_chat'),
        _sw('显示操练场', 'SidebarModulesAdmin_playground'),
        _sw('显示控制台', 'SidebarModulesAdmin_console'),
        _sw('显示定价', 'SidebarModulesAdmin_pricing'),
        _sw('顶部导航: 首页', 'HeaderNavModules_home'),
        _sw('顶部导航: 控制台', 'HeaderNavModules_console'),
        _sw('顶部导航: 定价', 'HeaderNavModules_pricing'),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  // ═══════ 功能开关 ═══════
  Widget _buildFeatures() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('核心功能', Icons.toggle_on, [
        _sw('启用注册', 'RegisterEnabled'),
        _sw('启用 OAuth', 'OAuthEnabled'),
        _sw('邮箱验证', 'EmailVerificationEnabled'),
        _sw('两步验证 (2FA)', 'TwoFactorAuthEnabled'),
      ]),
      _section('AI 功能', Icons.auto_awesome, [
        _sw('启用聊天', 'ChatEnabled'),
        _sw('启用绘图 (Midjourney)', 'DrawingEnabled'),
        _sw('启用任务', 'TaskEnabled'),
        _sw('启用数据导出', 'DataExportEnabled'),
        _sw('启用 Web 搜索', 'WebSearchEnabled'),
      ]),
      _section('聊天配置', Icons.chat, [
        _t('聊天页面 URL', 'ChatPageURL'),
        _t('聊天页面提示', 'ChatPageTip'),
      ]),
      _section('绘图配置', Icons.palette, [
        _t('MJ 图片代理', 'MJImageProxy'),
        _sw('MJ 不保存图片', 'MJNotSaveImage'),
      ]),
      _section('SSRF 防护', Icons.shield, [
        _sw('SSRF 防护总开关', 'SSRFProtectionEnabled'),
        _t('受信任域名 (一行一个)', 'SSRFTrustedDomains', maxLines: 3),
        _t('允许端口', 'SSRFAllowedPorts'),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  // ═══════ 模型配置 ═══════
  Widget _buildModels() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('全局设置', Icons.public, [
        _t('默认模型', 'DefaultModel'),
        _t('全局 Temperature', 'DefaultTemperature', isNum: true),
        _t('全局 Max Tokens', 'DefaultMaxTokens', isNum: true),
        _t('全局 Top P', 'DefaultTopP', isNum: true),
        _t('全局 Frequency Penalty', 'DefaultFrequencyPenalty', isNum: true),
      ]),
      _section('Claude 设置', Icons.psychology, [
        _t('Claude 思考适配百分比', 'ClaudeThinkingBudgetTokens', isNum: true),
        _t('Claude 请求头覆盖 (JSON)', 'ClaudeOverrideHeaders', maxLines: 3),
        _t('Claude 请求头追加 (JSON)', 'ClaudeAdditionalHeaders', maxLines: 3),
      ]),
      _section('Gemini 设置', Icons.g_mobiledata, [
        _t('Gemini 思考适配百分比', 'GeminiThinkingBudgetTokens', isNum: true),
        _t('Gemini 安全设置 (JSON)', 'GeminiSafetySettings', maxLines: 3),
        _t('Gemini 版本设置 (JSON)', 'GeminiVersionSettings', maxLines: 3),
      ]),
      _section('Grok 设置', Icons.rocket_launch, [
        _t('Grok 模型配置 (JSON)', 'GrokModelSettings', maxLines: 3),
      ]),
      _section('其他', Icons.more_horiz, [
        _sw('自动填充 thoughtSignature', 'AutoFillThoughtSignature'),
        _sw('Vertex AI 移除 functionResponse.id', 'VertexAIRemoveFunctionResponseId'),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  // ═══════ 支付配置 ═══════
  Widget _buildPayment() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('通用', Icons.payment, [
        _t('支付网关', 'PaymentGateway'),
        _t('支付地址', 'PayAddress'),
        _t('美元汇率', 'USDExchangeRate', isNum: true),
        _t('价格倍率', 'Price', isNum: true),
        _t('最低充值', 'MinTopUp', isNum: true),
      ]),
      _section('易支付', Icons.qr_code, [
        _t('易支付 ID', 'EpayId'),
        _t('易支付 Key', 'EpayKey', obscure: true),
      ]),
      _section('Stripe', Icons.credit_card, [
        _t('Stripe API Secret', 'StripeApiSecret', obscure: true),
        _t('Stripe Webhook Secret', 'StripeWebhookSecret', obscure: true),
        _t('Stripe Price ID', 'StripePriceId'),
        _t('Stripe 单价', 'StripeUnitPrice', isNum: true),
        _t('Stripe 最低充值', 'StripeMinTopUp', isNum: true),
      ]),
      _section('Creem', Icons.shopping_cart, [
        _sw('Creem 测试模式', 'CreemTestMode'),
        _t('Creem API Key', 'CreemApiKey', obscure: true),
        _t('Creem Webhook Secret', 'CreemWebhookSecret', obscure: true),
        _t('Creem 产品 (JSON)', 'CreemProducts', maxLines: 3),
      ]),
      _section('Waffo', Icons.wallet, [
        _sw('启用 Waffo', 'WaffoEnabled'),
        _t('Waffo API Key', 'WaffoApiKey', obscure: true),
        _t('Waffo Private Key', 'WaffoPrivateKey', obscure: true, maxLines: 3),
        _t('Waffo Public Cert', 'WaffoPublicCert', maxLines: 3),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  // ═══════ 限流配置 ═══════
  Widget _buildRateLimit() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('用户限流', Icons.person_off, [
        _t('每用户 RPM', 'UserRPM', isNum: true),
        _t('每用户 TPM', 'UserTPM', isNum: true),
        _t('VIP 每用户 RPM', 'VIPUserRPM', isNum: true),
        _t('VIP 每用户 TPM', 'VIPUserTPM', isNum: true),
      ]),
      _section('IP 限流', Icons.language, [
        _t('每 IP RPM', 'IPRPM', isNum: true),
        _t('IP 白名单', 'IPWhitelist'),
        _t('IP 黑名单', 'IPBlacklist'),
      ]),
      _section('模型请求限流', Icons.model_training, [
        _sw('启用模型请求限流', 'ModelRequestRateLimitEnabled'),
        _t('最大请求次数', 'ModelRequestRateLimitCount', isNum: true),
        _t('最大成功次数', 'ModelRequestRateLimitSuccessCount', isNum: true),
        _t('限流窗口 (分钟)', 'ModelRequestRateLimitDurationMinutes', isNum: true),
      ]),
      _section('分组倍率', Icons.groups, [
        _t('分组倍率 (JSON)', 'GroupRatio', maxLines: 3),
        _t('分组模型可用规则', 'GroupModelUsableRules', maxLines: 3),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  // ═══════ 仪表盘 ═══════
  Widget _buildDashboard() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _section('API 信息', Icons.api, [
        _sw('启用 API 信息', 'ConsoleAPIInfoEnabled'),
        _t('API 信息列表 (JSON)', 'APIInfoList', maxLines: 5),
      ]),
      _section('公告', Icons.campaign, [
        _t('公告内容', 'Announcement'),
        _t('公告类型', 'AnnouncementType'),
        _t('公告发布时间', 'AnnouncementDate'),
      ]),
      _section('数据看板', Icons.analytics, [
        _t('小时统计数', 'DashboardHourCount', isNum: true),
        _t('天统计数', 'DashboardDayCount', isNum: true),
        _t('周统计数', 'DashboardWeekCount', isNum: true),
      ]),
      _section('FAQ', Icons.help, [
        _sw('启用 FAQ', 'FAQEnabled'),
        _t('FAQ 内容 (JSON)', 'FAQContent', maxLines: 5),
      ]),
      _section('Uptime Kuma', Icons.monitor_heart, [
        _sw('启用 Uptime Kuma', 'UptimeKumaEnabled'),
        _t('Kuma 地址', 'UptimeKumaURL'),
        _t('监控分类 (JSON)', 'UptimeKumaCategories', maxLines: 3),
      ]),
      _section('定价页', Icons.attach_money, [
        _sw('显示定价页', 'PricingEnabled'),
        _sw('显示按次价格', 'PricingShowPerCall'),
        _t('定价币种', 'PricingCurrency'),
        _t('Token 单位', 'TokenUnit'),
      ]),
      const SizedBox(height: 32),
    ]);
  }
}
