# new-api Flutter 全平台客户端

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-AGPL%20v3-blue)](LICENSE)

**new-api 的 Flutter 跨平台客户端** — 将 [new-api](https://github.com/QuantumNous/new-api) Web 前端全部功能移植为 Flutter App，覆盖 Android / iOS / Windows / macOS / Linux / Web。

Web 版聊天基于 iframe 代理第三方页面，本客户端**原生实现 SSE 流式对话**。

## ✨ 功能

| 模块 | 功能 |
|------|------|
| 🔐 认证 | 账号密码登录、注册、密码重置、OAuth（GitHub/Discord/LinuxDO/OIDC） |
| 📊 控制台 | 仪表盘（额度/用量/快捷入口）、令牌管理 |
| 💬 聊天 | **原生 SSE 流式对话**、Markdown 渲染、代码高亮、参数面板、停止生成 |
| 🧪 操练场 | API 调试，模型选择 + 参数调节 + 自定义 JSON 请求体 + Debug 面板 |
| 📋 日志 | 使用日志（筛选/分页）、任务日志（类型/进度）、绘图日志（缩略图预览） |
| 💰 钱包 | 充值历史、支付方式映射、订单搜索 |
| ⚙️ 管理 | 渠道 CRUD、模型管理、用户管理、兑换码、订阅、系统设置（6 大类） |
| 💲 定价 | 厂商侧栏 + 模型卡片 + 输入/输出价格展示 |
| 👤 个人 | 资料编辑、密码修改、主题切换 |
| 🌐 多语言 | 中/英双语（233 键），JSON 懒加载，可扩展 |

## 🏗 架构

```
lib/
├── main.dart                    # 入口，窗口管理，多语言注册
├── router.dart                  # GoRouter 28 路由 + 3 级守卫
├── core/
│   ├── api/
│   │   ├── api_client.dart      # Dio HTTP 封装（拦截器/认证/重试）
│   │   └── sse_client.dart      # 原生 SSE 流式解析
│   └── theme/
│       └── app_theme.dart       # Material 3 深/浅主题
├── providers/                   # Riverpod 状态管理
│   ├── auth_provider.dart       # 认证状态
│   ├── theme_provider.dart      # 主题切换
│   └── status_provider.dart     # 系统状态
├── layout/                      # 响应式布局
│   ├── main_layout.dart         # 3 档断点（手机/平板/桌面）
│   ├── side_bar.dart            # 侧栏导航（4 组菜单）
│   └── header_bar.dart          # 顶栏
├── widgets/
│   └── common.dart              # CardPro / StatsCard 通用组件
├── l10n/                        # 多语言
│   ├── app_localizations.dart   # 本地化框架
│   ├── zh.json                  # 中文翻译（233 键）
│   └── en.json                  # 英文翻译
└── pages/
    ├── auth/                    # 登录/注册/密码重置
    ├── setup/                   # 服务器配置
    ├── dashboard/               # 仪表盘
    ├── chat/                    # SSE 流式聊天
    ├── playground/              # API 调试操练场
    ├── token/                   # 令牌管理
    ├── log_page/                # 使用日志
    ├── task/                    # 任务日志
    ├── midjourney/              # 绘图日志
    ├── topup/                   # 钱包管理
    ├── pricing/                 # 模型定价
    ├── personal/                # 个人设置
    ├── home/                    # 首页（未登录）
    ├── about/                   # 关于页
    └── admin/                   # 管理员
        ├── channel/             # 渠道管理
        ├── model/               # 模型管理
        ├── user/                # 用户管理
        ├── redemption/          # 兑换码
        ├── subscription/        # 订阅
        ├── deployment/          # 模型部署
        └── settings/            # 系统设置（6 大类）
```

## 📱 响应式设计

| 断点 | 宽度 | 布局 |
|------|------|------|
| 📱 手机 | < 600px | 底部导航栏 + Drawer 菜单 |
| 📋 平板 | 600-900px | 窄侧栏常驻 + Drawer 展开 |
| 🖥️ 桌面 | > 900px | 完整侧栏 + 顶栏 + 快捷键 |

### 快捷键（桌面端）

| 快捷键 | 操作 |
|--------|------|
| `Ctrl + B` | 折叠/展开侧栏 |
| `Ctrl + D` | 切换深/浅主题 |

## 🛠 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Flutter 3.41 / Dart 3.11 |
| 状态管理 | Riverpod |
| 路由 | GoRouter（声明式，28 路由 + 3 级守卫） |
| HTTP | Dio（拦截器/重试/SSE 流式） |
| 本地存储 | flutter_secure_storage + shared_preferences |
| 数据库 | drift (SQLite) |
| Markdown | flutter_markdown |
| 图表 | fl_chart |
| 窗口管理 | window_manager |

## 🚀 构建

### 前置条件

```bash
# Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Linux 桌面依赖
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev lld
```

### 运行

```bash
cd ~/code/new-api-client

# 桌面
flutter run -d linux

# Web
flutter run -d chrome

# 移动端（需模拟器/设备）
flutter run -d android
```

### 构建产物

```bash
flutter build linux --debug     # Linux ELF
flutter build web --debug       # Web (build/web/)
flutter build apk --debug       # Android APK
flutter build ios --debug       # iOS (macOS 上)
```

## 📋 开发进度

```
Phase 1 ✅ 需求分析 & 规格定义
Phase 2 ✅ 项目骨架（路由/API/Provider/主题/布局）
Phase 3 ✅ 核心功能（服务器→登录→Dashboard→SSE聊天→Key管理）
Phase 4 ✅ 管理功能（渠道/模型/用户/兑换码/订阅/系统设置）
Phase 5 ✅ 辅助功能（Playground/日志/钱包/定价/个人设置）
Phase 6 ✅ 打磨发布（多语言/响应式/窗口管理/构建验证）
```

## 📄 许可

本项目基于 [new-api](https://github.com/QuantumNous/new-api) 的 Web 前端逆向实现，遵循 AGPL v3.0 协议。
