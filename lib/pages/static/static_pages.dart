import 'package:flutter/material.dart';

// ── 403 禁止访问 ────────────────────────────────────────
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('403 Forbidden')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('403', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          const Text('禁止访问', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('你没有权限访问此页面', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('返回首页'),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ]),
      ),
    );
  }
}

// ── 404 未找到 ──────────────────────────────────────────
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 Not Found')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 80, color: Colors.orange.shade300),
          const SizedBox(height: 16),
          const Text('404', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          const Text('页面未找到', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('你访问的页面不存在或已被删除', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('返回首页'),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ]),
      ),
    );
  }
}

// ── 隐私政策 ────────────────────────────────────────────
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('隐私政策', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('最后更新：2025年1月', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 24),
          _Section(title: '1. 信息收集', content: '我们仅收集提供服务所必需的信息，包括：账户信息（用户名、邮箱）、API 使用数据（请求量、模型调用记录）、支付信息（充值记录，不存储完整支付凭证）。'),
          _Section(title: '2. 信息使用', content: '收集的信息用于：提供 API 代理服务、计费和配额管理、服务优化和故障排查、安全防护和滥用检测。'),
          _Section(title: '3. 数据存储', content: '用户数据存储在服务器本地数据库中。API 密钥和支付凭证通过加密存储。日志数据按配置保留期限自动清理。'),
          _Section(title: '4. 第三方共享', content: '我们不会向第三方出售用户数据。API 调用数据会转发至您选择的上游 AI 提供商以完成请求。支付数据会传输至您选择的支付网关。'),
          _Section(title: '5. 用户权利', content: '您有权：查看和修改个人信息、导出使用数据、删除账户及相关数据。如需行使这些权利，请联系管理员。'),
          _Section(title: '6. 联系我们', content: '如有隐私相关问题，请通过 GitHub Issues 或邮件联系我们。'),
        ]),
      ),
    );
  }
}

// ── 用户协议 ────────────────────────────────────────────
class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户协议')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('用户协议', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('最后更新：2025年1月', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 24),
          _Section(title: '1. 服务说明', content: 'New API 是一个 AI 模型 API 代理/网关服务，聚合多种 AI 提供商的 API 接口。用户通过本服务调用上游 AI 提供商的模型。'),
          _Section(title: '2. 使用规则', content: '用户不得：利用服务生成违法内容、对服务进行反向工程或攻击、绕过配额限制或滥用 API、转售或未授权分发 API 密钥。'),
          _Section(title: '3. 计费与退款', content: '服务按用量计费。具体价格以定价页为准。充值后不支持退款，除非因服务故障导致的计量错误。'),
          _Section(title: '4. 服务可用性', content: '服务按"现状"提供，不保证 100% 可用性。上游 AI 提供商的故障可能影响服务质量。我们尽力维护服务稳定。'),
          _Section(title: '5. 责任限制', content: '对于因使用本服务产生的任何间接损失，我们不承担责任。用户对通过本服务生成的内容负全部责任。'),
          _Section(title: '6. 协议变更', content: '我们保留修改本协议的权利。重大变更将通过公告通知。继续使用服务即表示接受修改后的协议。'),
          _Section(title: '7. 终止', content: '违反本协议的用户，我们有权暂停或终止其账户，且不退还余额。'),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),
      ]),
    );
  }
}
