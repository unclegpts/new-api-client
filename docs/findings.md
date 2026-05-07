# Findings — new-api Flutter 客户端 v2

## 2026-05-07 完整逆向分析

### Web 前端源码分析（`new-api/web/src/`）

#### Chat 是 iframe 代理 ⚠️
- `pages/Chat/index.jsx` 不实现聊天 UI
- 将 Token + 服务器地址拼入 iframe URL，加载第三方 Chat 应用
- Flutter 版**必须原生实现 SSE 聊天**，这是核心差异化

#### API 调用层
- axios 实例 + GET 去重（相同 URL+Params 只发一次）
- 全局错误拦截器（可 skipErrorHandler 跳过）
- 认证通过 `New-API-User` header

#### 状态管理
- 3 个 React Context：User（用户信息）、Status（全局配置）、Theme
- localStorage 作为持久层
- 每个页面独立管理自己的 fetch 状态

#### 组件体系
- 通用 UI 9 个：CardPro, CardTable, Loading, JSONEditor, MarkdownRenderer 等
- 表格模块 11 个，每个遵循 Actions/ColumnDefs/Filters/Table + modals 结构
- Layout: HeaderBar(9子组件) + SiderBar(4组导航) + Content + Footer

#### 侧边栏导航（4 组）
- Chat: 聊天列表 + Playground
- Console: 数据看板/令牌/日志/绘图/任务（部分条件显示）
- Personal: 钱包/个人设置
- Admin(role>=10): 渠道/订阅/模型/部署/兑换码/用户/设置(role>=100)

#### 认证机制
- JWT Token 存 localStorage.user.token
- 路由守卫：PrivateRoute / AdminRoute / AuthRedirect
- OAuth 支持 5 种：GitHub, Discord, OIDC, LinuxDO, Custom

#### 条件功能开关
- enable_data_export → 数据看板
- enable_drawing → 绘图日志
- enable_task → 任务日志
- chats → 聊天列表

### 设置面板完整分析
总计 15+ 子页面，分 8 大类：Chat/Dashboard/Drawing/Model/Operation/Payment/Performance/RateLimit/Ratio

### 关键架构决策
1. Web 版 Chat 是 iframe → Flutter 原生 SSE 聊天（核心差异化）
2. Web 版 11 个表格模块 → Flutter 统一 TableWidget 组件
3. Web 版 Context 三层 → Flutter Riverpod Provider
4. Web 版 localStorage → Flutter secure_storage + drift + prefs
5. 多语言直接复用 JSON 翻译文件（中文 key 查找）
