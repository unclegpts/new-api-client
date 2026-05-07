# Task Plan: new-api Flutter 全平台客户端 v2

## Goal
将 new-api Web 前端全部功能移植为 Flutter 跨平台 App，并**原生实现 SSE 流式聊天**（Web 版用 iframe 代理，不做）。

## Status
🎉 **全部完成 — 7/7 阶段** | `main@c59a46f` | 42 个 Dart 文件 | 17 tests | 0 analyze issues

## Phases

### Phase 1: 需求分析 & 规格定义 ✅
- [x] 分析 new-api Web 前端全量页面和路由（28页）
- [x] 深度逆向：API 层、状态管理、组件体系、认证流程
- [x] 发现 Web 版 Chat 是 iframe 代理 — Flutter 需原生实现
- [x] 分析 4 组导航结构 + 条件显示逻辑
- [x] 分析 11 个表格组件通用模式
- [x] 分析 15+ 设置子页面完整结构
- [x] spec.md v2.0 完成（含 Web↔Flutter 映射表）
- [x] findings.md v2 完成
- **Status:** complete

### Phase 2: 项目骨架 & 基础设施 ✅
- [x] GoRouter 路由表（28 路由 + 3 级守卫：公开/登录/管理员）
- [x] dio HTTP 封装 + SSE 流式客户端
- [x] Riverpod Provider 体系
- [x] 本地存储层（flutter_secure_storage + shared_preferences）
- [x] 主题系统（Material 3 深色/浅色/跟随系统）
- [x] 多语言框架 (AppLocalizations) + 嵌入翻译 JSON
- [x] 响应式 Layout（桌面侧栏 / 平板窄栏 / 移动端底部导航）
- [x] 通用 UI 组件库（DataTable 通用模式、PopupMenu 等）
- [x] 32 个 Dart 文件骨架一次性搭建
- **Status:** complete

### Phase 3: 核心功能 P0（MVP — 用户可用）✅
- [x] 登录/注册/密码重置（账号密码 + Passkey 入口 + 2FA 框架）
- [x] 服务器配置页（首次启动配置 API 地址）
- [x] 控制台 Dashboard（StatsCards + Charts）
- [x] 聊天页面（原生 SSE + Markdown 代码高亮）⭐ — 与 Web 版最大差异
- [x] Key 管理（完整 CRUD + 复制 + PopupMenu）
- [x] 侧边栏导航（4 组，条件显示）
- **Status:** complete

### Phase 4: 管理功能 P1（管理员可用）✅
- [x] 渠道管理（CRUD + 搜索/分页/状态过滤/测试连通/批量）
- [x] 模型管理（分类展开 + 搜索/添加/删除/过滤）
- [x] 用户管理（搜索/编辑/删除/角色标签/PopupMenu）
- [x] 兑换码（余额/状态标签）
- [x] 订阅管理（套餐 + 用户关联）
- [x] 系统设置（6 选项卡 80+ 配置项：运营23/功能15/模型14/支付15/限流12/仪表盘12）
- **Status:** complete

### Phase 5: 辅助功能 P2（完整体验）✅
- [x] 操练场 Playground（SSE 流式调试 + 参数面板 + Debug 双栏）
- [x] 绘图日志（缩略预览 + JSON 处理）
- [x] 钱包管理（充值历史 + 支付映射）
- [x] 日志查询：使用日志（DataTable+筛选+分页）/ 任务日志（类型彩标+进度条）
- [x] 定价页（厂商侧栏 + 模型卡片 + 实时 API 数据）
- [x] 个人设置（资料编辑 + 密码修改 + 主题切换 + 退出登录）
- [x] ModelDeployment（列表+分页+创建弹窗+删除）
- [x] Chat2Link（对话分享链接生成+复制）
- [x] 静态页面（403/404/隐私政策/用户协议）
- **Status:** complete

### Phase 6: 打磨 & 发布 P3 ✅
- [x] 多语言（中/英，233 键）
- [x] 移动端适配（底部导航栏 + Drawer）
- [x] 桌面端适配（窗口管理 + Ctrl+B 折叠 / Ctrl+D 主题 / 最小 800×600）
- [x] 全局搜索弹窗（Ctrl+F）
- [x] 全局公告弹窗
- [x] .gitignore 完整 + git init + GitHub 推送
- [x] 安全扫描 — 无硬编码密钥/危险函数/调试残留
- [x] 17 个测试（api_client 4 + SSE 4 + i18n 4 + setup 3）全部通过
- [x] flutter analyze — No issues found
- [x] Linux 构建成功 (53KB ELF)
- [x] Web 构建成功
- **Status:** complete

### Phase 7: 功能缺口补齐 ✅
- [x] Settings 完整重写（从 ~15 个开关扩展到 6 选项卡 80+ 配置项）
- [x] Token 管理完整化（创建/编辑/删除/复制 Key）
- [x] User 管理完整化（编辑/删除/PopupMenu）
- [x] Model 管理完整化（搜索/删除/过滤）
- [x] Channel 管理完整化（搜索/分页/状态过滤/测试连通）
- [x] 认证增强（Passkey 入口 + 2FA 框架）
- [x] 全局搜索弹窗 + 公告弹窗
- [x] 7 文件变更 | +618 -298 行
- **Status:** complete

## Commits

```
c59a46f feat: 补齐 CRUD 核心功能 — Token/User/Model/Channel 完整化 + 全局搜索/公告
67d9131 feat: 补齐缺失功能 — Settings完整化 + ModelDeployment + Chat2Link + 静态页面
9200002 chore: 代码质量优化 — 安全扫描 + 测试覆盖 + 内存泄漏检查
c60da2d feat: new-api Flutter 全平台客户端 v1.0
```

## Key Questions
1. ✅ P0 聊天是原生实现还是 WebView 加载第三方？→ 原生 SSE
2. ✅ 移动端优先还是桌面端优先？→ 先桌面端验证，再移动端适配
3. ✅ OAuth 登录在移动端如何处理？→ WebView 拦截回调

## Decisions Made
| 决策 | 理由 |
|------|------|
| 纯 Flutter，不上 Rust | 无性能敏感计算，HTTP+SSE Dart 完全够用 |
| Riverpod 状态管理 | 编译安全、Provider 替代 |
| GoRouter 路由 | 声明式、深链接、Web/移动一致 |
| dio HTTP | 拦截器/重试/SSE 支持好 |
| 原生 SSE 聊天 | Web 版是 iframe，无参考价值 |
| 多语言复用 JSON | 避免重复翻译，与 Web 版一致 |
| 桌面端优先 | 开发调试快，验证后再适配移动端 |
| 响应式布局 | 移动端底部导航，桌面端固定侧栏 |
| Material 3 | 深色/浅色/跟随系统三模式 |
