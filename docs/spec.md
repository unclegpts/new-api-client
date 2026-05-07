# Spec: new-api Flutter 全平台客户端 v2.0

> 规格版本: v2.0 | 对标: new-api Web 前端 v1.x | 目标: 功能完全对等 + 原生聊天体验
> 基于 2026-05-07 完整逆向分析 new-api/web/ 源码

---

## 1. Web 前端逆向分析总结

### 1.1 技术栈
| 层 | Web 版 | Flutter 版 |
|----|--------|------------|
| 框架 | React 18 + Vite | Flutter 3.41 |
| UI 库 | Semi Design (@douyinfe/semi-ui) | Material 3 自定义 |
| 状态 | React Context (User/Status/Theme) | Riverpod |
| HTTP | axios (GET 去重) | dio |
| 路由 | react-router-dom v6 | GoRouter |
| 存储 | localStorage | secure_storage + drift + prefs |
| 多语言 | i18next + react-i18next | flutter_localizations |
| 包管理 | Bun | dart pub |
| 图标 | Lucide React | lucide_flutter |

### 1.2 关键发现：Web 版聊天是 iframe 代理
- Web 版 `pages/Chat/index.jsx` **不实现聊天 UI**
- 实际是将 Token 填入 iframe，加载第三方 Chat 应用（如 OpenWebUI）
- Flutter 版必须**原生实现 SSE 流式聊天**，这是核心差异化价值

### 1.3 导航结构（4 组）
```
侧边栏
├── 💬 聊天 (Chat)
│   ├── 操练场 (Playground)
│   └── 聊天列表 (动态从 localStorage.chats 加载)
├── 📊 控制台 (Console) — 所有用户可见
│   ├── 数据看板 (Dashboard)       — 条件显示: enable_data_export
│   ├── 令牌管理 (Token)
│   ├── 使用日志 (Log)
│   ├── 绘图日志 (Midjourney)      — 条件显示: enable_drawing
│   └── 任务日志 (Task)            — 条件显示: enable_task
├── 👤 个人中心 (Personal)
│   ├── 钱包管理 (TopUp)
│   └── 个人设置 (Personal Setting)
└── 🔧 管理员 (Admin) — role >= 10 可见
    ├── 渠道管理 (Channel)
    ├── 订阅管理 (Subscription)
    ├── 模型管理 (Models)
    ├── 模型部署 (Deployment)
    ├── 兑换码管理 (Redemption)
    ├── 用户管理 (User)
    └── 系统设置 (Setting)         — role >= 100 (Root)
```

---

## 2. 页面完整清单（28 页）

### 2.1 公开页面（11 页）
| # | 页面 | 路由 | Web 组件 | Flutter 实现 |
|---|------|------|----------|-------------|
| 1 | 首页 | `/` | `pages/Home` (lazy) | LandingPage |
| 2 | 登录 | `/login` | `LoginForm` | LoginPage（账号+OAuth列表） |
| 3 | 注册 | `/register` | `RegisterForm` | RegisterPage |
| 4 | 密码重置 | `/reset` | `PasswordResetForm` | ResetPasswordPage |
| 5 | 重置确认 | `/user/reset` | `PasswordResetConfirm` | ResetConfirmPage |
| 6 | OAuth回调 | `/oauth/:provider` | `OAuth2Callback` | OAuthCallbackPage（WebView拦截） |
| 7 | 初始化 | `/setup` | `Setup` + `SetupCheck` | SetupWizardPage |
| 8 | 定价 | `/pricing` | `pages/Pricing` | PricingPage |
| 9 | 关于 | `/about` | `pages/About` (lazy) | AboutPage |
| 10 | 用户协议 | `/user-agreement` | `pages/UserAgreement` (lazy) | AgreementPage |
| 11 | 隐私政策 | `/privacy-policy` | `pages/PrivacyPolicy` (lazy) | PrivacyPage |

### 2.2 需登录页面（9 页）
| # | 页面 | 路由 | Web 组件 | Flutter 实现 |
|---|------|------|----------|-------------|
| 12 | 控制台 | `/console` | `Dashboard` + `StatsCards` + `ChartsPanel` | DashboardPage |
| 13 | 聊天 ⭐ | `/console/chat/:id?` | **iframe 代理** | **ChatPage（原生 SSE）** |
| 14 | Key管理 | `/console/token` | `TokensTable` + `TokensFilters` + `TokensActions` | TokenListPage |
| 15 | Playground | `/console/playground` | `Playground` + `PlaygroundContext` | PlaygroundPage |
| 16 | 充值 | `/console/topup` | `TopUp` + `modals` | TopUpPage |
| 17 | Midjourney | `/console/midjourney` | `MjLogsTable` | MidjourneyPage |
| 18 | 日志 | `/console/log` | `UsageLogsTable` | LogPage |
| 19 | 任务 | `/console/task` | `TaskLogsTable` | TaskPage |
| 20 | 个人设置 | `/console/personal` | `PersonalSetting` | PersonalSettingPage |

### 2.3 管理员页面（6 页）
| # | 页面 | 路由 | Web 组件 | Flutter 实现 |
|---|------|------|----------|-------------|
| 21 | 渠道管理 | `/console/channel` | `ChannelsTable` | ChannelListPage |
| 22 | 模型管理 | `/console/models` | `ModelsTable` | ModelListPage |
| 23 | 模型部署 | `/console/deployment` | `ModelDeploymentsTable` | DeploymentPage |
| 24 | 用户管理 | `/console/user` | `UsersTable` | UserListPage |
| 25 | 兑换码 | `/console/redemption` | `RedemptionsTable` | RedemptionPage |
| 26 | 订阅 | `/console/subscription` | `SubscriptionsTable` | SubscriptionPage |
| 27 | 系统设置 | `/console/setting` | `Setting` (15子页) | SettingsHubPage |
| 28 | 403 | `/forbidden` | `Forbidden` | ForbiddenPage |

---

## 3. 布局架构

### 3.1 整体结构
```
┌─────────────────────────────────────────┐
│  HeaderBar (64px 固定)                   │
│  Logo | 导航 | 通知 | 语言 | 主题 | 用户  │
├────────┬────────────────────────────────┤
│SiderBar│  Content (Scrollable)           │
│260px   │  ← 各页面在此渲染               │
│可折叠  │                                 │
├────────┴────────────────────────────────┤
│  Footer (可选)                           │
└─────────────────────────────────────────┘
```

### 3.2 HeaderBar 组件（9 个子组件）
| 组件 | Web 实现 | Flutter 对应 |
|------|---------|-------------|
| HeaderLogo | 系统名 + Logo | `branding` widget |
| Navigation | 顶栏链接（可配置） | 从 Status API 动态加载 |
| LanguageSelector | i18n 切换 | `PopupMenuButton` |
| ThemeToggle | 深色/浅色 | `IconButton` toggle |
| NotificationButton | 公告弹窗 | `NoticeModal` |
| UserArea | 用户头像/下拉菜单 | `PopupMenuButton` |
| ActionButtons | 自定义按钮 | 可配置 |
| MobileMenuButton | 移动端抽屉开关 | `Drawer` trigger |
| NewYearButton | 新年彩蛋 | 忽略 |

### 3.3 侧边栏行为
- 桌面端：260px 固定宽度，可折叠到 60px（仅图标）
- 平板端：默认折叠，展开时覆盖内容
- 移动端：Drawer 抽屉，从左侧滑出
- 菜单项根据 `StatusContext.HeaderNavModules` 配置动态显隐

### 3.4 使用 CardPro 布局的页面
`/console/channel`, `/console/log`, `/console/redemption`, `/console/user`, `/console/token`, `/console/midjourney`, `/console/task`

---

## 4. 认证与鉴权

### 4.1 Web 版认证机制
```
POST /api/user/login → { success, data: "JWT_TOKEN" }
    ↓
localStorage.setItem('user', JSON.stringify({ token: "xxx", role: 10, ... }))
    ↓
axios headers: { 'New-API-User': userId }
    ↓
API 拦截器: 401 → 跳转登录页
```

### 4.2 路由守卫
- `AuthRedirect`：已登录用户访问 `/login` → 重定向到 `/console`
- `PrivateRoute`：未登录 → 重定向到 `/login`（保存来源路径）
- `AdminRoute`：role < 10 → 重定向到 `/forbidden`
- Root 检查 (`isRoot()`)：role >= 100 才能访问系统设置

### 4.3 OAuth 支持
| Provider | Web 实现 | Flutter 方案 |
|----------|---------|-------------|
| GitHub | `onGitHubOAuthClicked` | WebView 或 `url_launcher` |
| Discord | `onDiscordOAuthClicked` | 同上 |
| OIDC | `onOIDCClicked`（支持新标签页） | 同上 |
| LinuxDO | `onLinuxDOOAuthClicked` | 同上 |
| 自定义 | `onCustomOAuthClicked` | 同上 |

### 4.4 Flutter 认证方案
```
用户输入服务器URL + 用户名密码
    ↓
POST {serverUrl}/api/user/login → JWT Token
    ↓
Token 存入 flutter_secure_storage
    ↓
dio interceptor: Authorization: Bearer {token}
    ↓
OAuth: WebView 打开授权页 → 监听 URL 变化 → 提取 code → POST /api/oauth/token
```

---

## 5. 数据流与 API

### 5.1 API 端点分类

| 类别 | 端点前缀 | Web Hook 示例 |
|------|---------|-------------|
| 用户 | `/api/user/*` | 登录/注册/信息/密码 |
| 令牌 | `/api/token/*` | `useTokensData` CRUD |
| 渠道 | `/api/channel/*` | `useChannelsData` CRUD |
| 日志 | `/api/log/*` | `useUsageLogsData` 分页查询 |
| 模型 | `/api/models/*` | `loadChannelModels` |
| 定价 | `/api/pricing/*` | `useModelPricingData` |
| 兑换码 | `/api/redemption/*` | `useRedemptionsData` |
| 用户管理 | `/api/user/manage/*` | `useUsersData` |
| 订阅 | `/api/subscription/*` | `useSubscriptionsData` |
| Dashboard | `/api/dashboard/*` | `useDashboardData` + stats + charts |
| 状态 | `/api/status` | 全局配置/公告 |
| OAuth | `/api/oauth/*` | 授权流程 |
| 设置 | `/api/setting/*` | 系统设置 CRUD |
| Midjourney | `/api/mj/*` | 绘图相关 |
| Playground | `/api/playground/*` | API 测试 |

### 5.2 Web 版数据 fetch 模式
```javascript
// 每个功能模块遵循相同模式
function useTokensData() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ page: 1, size: 10 });

  const fetch = async () => {
    setLoading(true);
    const res = await API.get('/api/token/', { params: { p, size } });
    setData(res.data.data);
    setLoading(false);
  };

  useEffect(() => { fetch(); }, [pagination]);
  return { data, loading, pagination, setPagination, refetch: fetch };
}
```

### 5.3 Web 版 API 去重机制
```javascript
// axios GET 请求去重 — 相同 URL+Params 同时只发一个请求
const inFlightGetRequests = new Map();
// 相同 key 的请求复用已有 Promise
```

### 5.4 条件功能开关
Web 版通过 `localStorage` 控制功能显隐：
| Key | 影响 |
|-----|------|
| `enable_data_export` | 数据看板入口 |
| `enable_drawing` | 绘图日志入口 |
| `enable_task` | 任务日志入口 |
| `chats` | 聊天列表（JSON 数组） |
| `channel_models` | 模型缓存 |

---

## 6. 组件体系（Web → Flutter 映射）

### 6.1 通用 UI 组件
| Web 组件 | 功能 | Flutter 替代 |
|----------|------|-------------|
| `CardPro` | 带标题的卡片容器 | `Card` widget |
| `CardTable` | 卡片+表格组合 | `Card` + `DataTable` |
| `Loading` | 加载指示器 | `CircularProgressIndicator` |
| `JSONEditor` | JSON 编辑 | `TextFormField` + 语法高亮 |
| `MarkdownRenderer` | Markdown 渲染 | `flutter_markdown` |
| `ScrollableContainer` | 滚动容器 | `SingleChildScrollView` |
| `SelectableButtonGroup` | 按钮组选择 | `SegmentedButton` 或 `ToggleButtons` |
| `ChannelKeyDisplay` | 渠道 Key 显示 | 自定义 widget |
| `CompactModeToggle` | 紧凑模式开关 | `Switch` |

### 6.2 表格组件通用结构
每个表格功能模块遵循相同结构：
```
components/table/{name}/
├── {Name}Table.jsx        → 主表格（分页/排序/选择）
├── {Name}Filters.jsx      → 筛选条件
├── {Name}Actions.jsx      → 操作按钮（新增/刷新/导出）
├── {Name}ColumnDefs.jsx   → 列定义
├── {Name}Description.jsx  → 页面描述/提示
├── index.jsx              → 组装入口
└── modals/                → 弹窗（新增/编辑/删除确认）
```

11 个表格模块：`tokens`, `channels`, `users`, `usage-logs`, `mj-logs`, `task-logs`, `models`, `model-deployments`, `model-pricing`, `redemptions`, `subscriptions`

---

## 7. 聊天页面 ⭐（原生实现）

### 7.1 与 Web 版的差异
| | Web 版 | Flutter 版 |
|---|--------|-----------|
| 实现方式 | iframe 加载第三方 Chat 应用 | 原生 Dart SSE 流式渲染 |
| 聊天存储 | 依赖第三方应用 | 本地 drift SQLite |
| 消息历史 | 第三方管理 | 本地持久化 |
| 模型切换 | 第三方选择器 | 原生选择器 |
| 离线查看 | 不支持 | 支持（已缓存对话） |

### 7.2 功能清单
- [x] 模型选择器（搜索/分组）
- [x] SSE 流式对话（逐 token 渲染）
- [x] Markdown + 代码高亮渲染
- [x] 对话列表（新建/删除/重命名）
- [x] 消息操作（复制/重新生成/编辑）
- [x] 参数面板（temperature, max_tokens, top_p, presence_penalty）
- [x] System Prompt 设置
- [x] 上下文管理（消息数量限制）
- [x] 流中断重连

### 7.3 SSE 数据流
```
用户输入消息
    ↓
POST /v1/chat/completions {
  model, messages, stream: true,
  temperature, max_tokens, ...
}
    ↓
dio Response (streaming)
    ↓
逐行解析: "data: {...}" → JSON decode → delta.content
    ↓
StreamBuilder 更新 UI → Markdown 渲染
    ↓ stream done: [DONE]
保存完整对话到 SQLite
```

---

## 8. Dashboard 数据看板

### 8.1 Web 版组件
| 组件 | 功能 |
|------|------|
| `DashboardHeader` | 标题 + 时间范围选择 |
| `StatsCards` | 统计卡片（今日调用/花费/用户数） |
| `ChartsPanel` | 图表面板（调用趋势/模型分布） |
| `AnnouncementsPanel` | 公告面板 |
| `ApiInfoPanel` | API 信息 |
| `FaqPanel` | FAQ |
| `UptimePanel` | 运行时间 |

### 8.2 Dashboard hooks
- `useDashboardData` — 基础统计数据
- `useDashboardStats` — 统计卡片数据
- `useDashboardCharts` — 图表数据

---

## 9. 设置面板（15 子页）

```
/console/setting
├── Chat 设置
│   └── SettingsChats
├── Dashboard 设置
│   ├── SettingsAnnouncements    — 公告管理
│   ├── SettingsAPIInfo          — API 信息
│   ├── SettingsDataDashboard    — 数据看板
│   ├── SettingsFAQ              — FAQ
│   └── SettingsUptimeKuma       — Uptime Kuma
├── Drawing 设置
│   └── SettingsDrawing          — 绘图配置
├── Model 设置
│   ├── SettingClaudeModel       — Claude 模型
│   ├── SettingGeminiModel       — Gemini 模型
│   ├── SettingGrokModel         — Grok 模型
│   ├── SettingGlobalModel       — 全局模型配置
│   └── SettingModelDeployment   — 模型部署
├── Operation 设置
│   ├── SettingsChannelAffinity  — 渠道亲和
│   ├── SettingsCheckin          — 签到
│   ├── SettingsCreditLimit      — 信用额度
│   ├── SettingsGeneral          — 运营通用
│   ├── SettingsHeaderNavModules — 顶栏模块
│   ├── SettingsLog              — 日志设置
│   ├── SettingsMonitoring       — 监控
│   ├── SettingsSensitiveWords   — 敏感词
│   └── SettingsSidebarModules   — 侧边栏模块（Admin）
├── Payment 设置
│   ├── SettingsGeneralPayment   — 通用支付
│   ├── SettingsPaymentGateway   — 支付网关
│   ├── SettingsPaymentGatewayStripe
│   ├── SettingsPaymentGatewayCreem
│   └── SettingsPaymentGatewayWaffo
├── Performance 设置
│   └── SettingsPerformance
├── RateLimit 设置
│   └── SettingsRequestRateLimit
└── Ratio 设置
    ├── GroupRatioSettings       — 分组倍率
    ├── ModelRatioSettings       — 模型倍率
    ├── ModelPricingCombined     — 模型定价
    ├── ModelSettingsVisualEditor— 可视化编辑
    ├── UpstreamRatioSync        — 上游同步
    └── components/              — 复用组件
```

---

## 10. 多语言 (i18n)

### 10.1 策略
直接复用 new-api Web 版翻译文件：
- `web/src/i18n/locales/{lang}.json`
- 格式：`{ "中文key": "翻译文本" }`
- 支持语言：zh(默认), en, fr, ru, ja, vi

### 10.2 Flutter 集成
```dart
// 用 easy_localization 或自定义方案
// 打包时将 JSON 文件复制到 assets/i18n/
// 使用 t('数据看板') 按中文 key 查找翻译
```

---

## 11. 非功能需求（更新）

| 需求 | 指标 |
|------|------|
| 冷启动 | < 2s（所有平台） |
| SSE 首 token | < 500ms |
| 包体积 | Android < 35MB, iOS < 55MB, Desktop < 80MB |
| 离线 | 无网络时显示缓存对话历史 |
| 安全 | Key/Token 用 flutter_secure_storage，不写日志 |
| 多语言 | zh/en/ja/fr/ru/vi，与 Web 版一致 |
| 主题 | 深色/浅色/跟随系统 三模式 |
| 响应式 | 手机/平板/桌面三种布局自适应 |

---

## 12. 依赖清单（完整）

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # 路由
  go_router: ^14.8.1
  
  # 网络
  dio: ^5.7.0
  
  # 存储
  flutter_secure_storage: ^9.2.4
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  shared_preferences: ^2.3.4
  path_provider: ^2.1.5
  
  # UI
  flutter_markdown: ^0.7.6
  google_fonts: ^6.2.1
  fl_chart: ^0.70.2
  lucide_flutter: ^0.1.0
  
  # 交互
  webview_flutter: ^4.10.0      # OAuth 登录
  url_launcher: ^6.3.1
  
  # 工具
  package_info_plus: ^8.1.2
  intl: ^0.19.0                  # 国际化
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  drift_dev: ^2.22.0
  riverpod_generator: ^2.6.0
  flutter_lints: ^5.0.0
```

---

## 13. v1 范围外（不变）
- ❌ 不复刻 new-api 后端功能
- ❌ 不内嵌模型推理
- ❌ 不实现 Electron 桌面壳（Flutter 原生桌面替代）
- ❌ Flutter Web 不优先（可用但不作为主要平台）
