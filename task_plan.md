# Task Plan: new-api Flutter 全平台客户端 v2

## Goal
将 new-api Web 前端全部功能移植为 Flutter 跨平台 App，并**原生实现 SSE 流式聊天**（Web 版用 iframe 代理，不做）。

## Current Phase
🎉 全部完成 — 6/6 阶段

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

### Phase 2: 项目骨架 & 基础设施
- [ ] GoRouter 路由表（28 路由 + 守卫）
- [ ] dio HTTP 封装 + SSE 客户端
- [ ] Riverpod Provider 体系
- [ ] 本地存储层（secure_store + drift + prefs）
- [ ] 主题系统（深色/浅色/跟随系统）
- [ ] 多语言框架 + 嵌入翻译 JSON
- [ ] Layout 框架（HeaderBar + SiderBar + 响应式）
- [ ] 通用 UI 组件库（CardPro 等效、Table 通用组件等）
- **Status:** pending

### Phase 3: 核心功能 P0（MVP — 用户可用）
- [ ] 登录/注册/密码重置（账号 + OAuth）
- [ ] 控制台 Dashboard（StatsCards + Charts）
- [ ] 聊天页面（原生 SSE）⭐ — 与 Web 版最大差异
- [ ] Key 管理
- [ ] 侧边栏导航（4 组，条件显示）
- **Status:** pending

### Phase 4: 管理功能 P1（管理员可用）
- [ ] 渠道管理
- [ ] 模型管理
- [ ] 用户管理
- [ ] 兑换码
- [ ] 订阅管理
- [ ] 系统设置面板（15 子页）
- **Status:** pending

### Phase 5: 辅助功能 P2（完整体验）✅
- [x] Playground API 调试
- [x] Midjourney 图片生成
- [x] 充值
- [x] 日志查询（使用/绘图/任务）
- [x] 定价页
- [x] 个人设置
- **Status:** complete

### Phase 6: 打磨 & 发布 P3 ✅
- [x] 多语言（中/英，233键）
- [x] 移动端适配（底部导航栏 + Drawer）
- [x] 桌面端适配（窗口管理 + Ctrl+B/Ctrl+D 快捷键）
- [x] flutter analyze — No issues found
- [x] Linux 构建成功 (53KB ELF)
- [x] Web 构建成功
- **Status:** complete

## Key Questions
1. ✅ P0 聊天是原生实现还是 WebView 加载第三方？→ 原生 SSE
2. 移动端优先还是桌面端优先？→ 先桌面端验证，再移动端适配
3. ✅ OAuth 登录在移动端如何处理？→ WebView 拦截回调

## Decisions Made
| 决策 | 理由 |
|------|------|
| 纯 Flutter，不上 Rust | 无性能敏感计算，HTTP+SSE Dart 完全够用 |
| Riverpod 状态管理 | 编译安全、Provider 替代 |
| GoRouter 路由 | 声明式、深链接、Web/移动一致 |
| dio HTTP | 拦截器/重试/SSE 支持好 |
| drift SQLite | 类型安全、跨平台 |
| 原生 SSE 聊天 | Web 版是 iframe，无参考价值 |
| 多语言复用 JSON | 避免重复翻译，与 Web 版一致 |
| 表格通用组件 | 11 个表格模块复用同一套模式 |
| 桌面端优先 | 开发调试快，验证后再适配移动端 |
