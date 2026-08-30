# 🎯 Target

![Platform: Cross-platform](https://img.shields.io/badge/Platform-Win%20%7C%20Mac%20%7C%20Linux%20%7C%20iOS%20%7C%20Android-lightgrey.svg)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.44.0-02569B?logo=flutter)](https://flutter.dev/)

**Target** 是一个基于 Flutter 构建的现代化、跨平台代理客户端。

其界面层通过本地认证的 gRPC 命令服务与底层的 **[TargetLib](https://github.com/TargetProxy/TargetLib)** 核心进行通信。应用专注于提供优秀的交互体验，而订阅解析、运行时配置、代理生命周期及日志管理等繁重的底层能力，均由 `TargetLib` 完美接管。

> ⚠️ **项目状态：积极开发中 (WIP)**
> 当前仓库代码已支持跨平台构建应用，但**尚未提供**经过完整签名、绝对稳定的全平台官方发行版。请勿将其用于生产环境的直接分发。

---

## ✨ 核心特性

*   🛠 **核心服务管理**：检测并启动由平台安装程序注册的 TargetLib 桌面服务。
*   📡 **高级订阅体验**：支持添加、更新和切换订阅，直观展示流量使用情况、到期时间及更新状态。
*   🌍 **可视化节点管理**：自动从订阅节点构建代理列表，支持全局搜索、节点测速、国家/地区智能分组，以及炫酷的**世界地图视图**。
*   ⚙️ **灵活的代理策略**：
    *   **代理模式**：支持 `Mixed` / `TUN` 模式切换。
    *   **路由模式**：支持 `All` / `Rule` / `Direct` 全局管控。
    *   **网络配置**：自定义监听地址、混合端口，并全面支持 IPv6。
*   🔍 **网络与日志洞察**：
    *   **IP 探测**：直观显示当前出口 IP，以及国家、城市、ISP、组织机构和 ASN 数据（由 TargetLib 强力驱动）。
    *   **日志系统**：支持应用与 TargetLib 双端日志的查看、筛选、暂停与清空；导出时贴心提供 **URL、IP 和 Token 隐私打码** 功能。
*   💻 **桌面端深度融合**：原生级系统托盘支持、关闭窗口自动隐藏、托盘快捷控制（连接/断开），以及严格的单实例运行保障。
*   🎨 **跨平台自适应 UI**：内置中英双语（i18n），持久化存储（`SharedPreferences`）个性化主题与代理设置，自适应桌面端宽屏侧栏与移动端底部导航。

---

## 🚧 当前限制与已知问题

*   **流量与连接看板**：UI 页面已就绪，但 `TargetLibGateway` 尚未正式订阅实时数据流，当前无法展示真实的实时网络快照。
*   **规则集刷新**：`refreshRuleSets()` 当前为空实现（固定返回 `0`）。
*   **构建与打包**：
    *   **Windows**：安装包暂无签名；NSIS 负责应用文件、TargetLib 服务注册、启动与卸载。
    *   **Android / iOS**：Android 仅使用 debug 签名；iOS CI 依赖 `--no-codesign`，无法直接作为正式 Release。
*   **CI 工作流**：`.github/workflows/build.yml` 中定义的多平台构建，由于 TargetLib 仓库移除了 `scripts/build.ps1` 而存在断链。在修复前，CI 无法作为五端构建的可靠验证。

---

## 🖥 平台支持状态

| 平台 | 运行模式 | 当前进度与现状 |
| :--- | :--- | :--- |
| **Windows** | 桌面服务 | ✅ 已接入服务安装、检测/启动、托盘、单实例及 NSIS 脚本。**支持最完善**。 |
| **Linux** | 桌面服务 | 🚧 Flutter runner、托盘与服务能力已就绪。发布需补充 TargetLib 产物。 |
| **macOS** | 桌面服务 | 🚧 基础能力已配置（可生成项目）。正式分发亟需解决苹果签名与公证。 |
| **Android** | 移动 VPN | 🚧 启动时主动请求 VPN 权限并以 VPN 模式运行。Release 签名待配置。 |
| **iOS**     | 移动 VPN | 🚧 采用网络扩展模型。CI 仅验证无签名构建，暂无直接发布配置。 |

> *注：上述状态仅代表当前代码库进度，并不意味着所有平台均已通过严苛的端到端测试。*

---

## 🏗 架构与结构

### 目录结构
```text
Target/
├── lib/
│   ├── app/             # 应用入口、路由、托盘系统和单实例控制
│   ├── core/            # TargetLib 网关、平台底层能力、日志拦截和主题引擎
│   ├── data/            # 状态管理：应用配置与运行时数据模型
│   └── features/        # 业务模块：首页、订阅/代理、连接、流量和日志面板
├── assets/              # 静态资源：应用图标和世界地图拓扑数据
├── test/                # 质量保证：单元测试与组件级测试
├── tool/                # 开发者工具：TargetLib 调试脚本
├── stage/windows/       # 打包分发：Windows NSIS 配置和脚本
└── .github/workflows/   # 持续集成：多平台自动构建工作流

```

### 核心调用链路

界面层完全解耦，不直接依赖底层的 protobuf 类型。数据流向清晰单向：

```text
Flutter UI
 └─> Riverpod Notifier (状态管理)
      └─> CoreGateway / SubscriptionGateway (业务网关)
           └─> TargetLibGateway (底层服务抽象)
                └─> TargetLib Flutter Package (核心 SDK)
                     └─> 本地认证 gRPC 命令服务
                          └─> 🚀 sing-box 代理引擎

```

---

## 🛠 开发指南

### 环境要求

* **Flutter**: `>=3.44.0` (同时要求 Dart `>=3.12.2 <4.0.0`)
* **Go**: 用于本地构建 TargetLib 核心服务
* **TargetLib 源码**: 需与本仓库处于**同级目录**（`pubspec.yaml` 强依赖 `../TargetLib/flutter` 路径）
* 对应目标平台的原生构建工具链 (Visual Studio / Xcode / Android Studio 等)

**推荐的本地工作区目录结构：**

```text
Workspace/
├── Target/       # 本仓库
└── TargetLib/    # 核心库仓库

```

### 检查与测试

```bash
# 静态代码分析
flutter analyze

# 运行全量测试
flutter test

```

### 多平台本地构建

需在对应的宿主操作系统上执行（如 macOS / iOS 只能在 Mac 环境下编译）：

```bash
flutter build windows --debug
flutter build linux --debug
flutter build apk --debug
flutter build macos --debug
flutter build ios --debug --no-codesign

```

### 🪲 调试 TargetLib 订阅

我们内置了一个实用的诊断脚本，允许您直接与本地运行的 TargetLib gRPC 服务对话，快速排查订阅与节点解析问题：

```bash
# 执行前请确保本地 TargetLib 命令服务已启动并处于监听状态
dart run tool/list_targetlib_subscriptions.dart

```

---

## 📄 许可证

**Target** 应用层源代码基于 **[AGPL-3.0](https://www.google.com/search?q=LICENSE)** (GNU Affero General Public License v3.0) 协议开源。
*说明：底层的 TargetLib 为独立项目，适用其自身仓库声明的开源许可证（GPL）。*

```

### 💡 美化细节说明：
1. **统一的设计语言**：与 `TargetLib` 保持了一致的 Badge 风格和 Emoji 排版规范，体现出“同一个项目生态”的专业感。
2. **状态高亮**：增加了警告引用块 `> ⚠️ **项目状态**`，让访问者第一时间意识到这不是一个可以直接下载使用的成品，管理期望值。
3. **架构调用链视觉化**：将文字版的调用链改成了一个树形箭头图 `└─>`，能够更直观地体现从 UI 到 `sing-box` 的分层解耦思想。
4. **表格优化**：平台状态表增加了进度 Emoji (✅ 和 🚧)，不仅美观，还能让人一眼扫过就知道哪些平台完善，哪些还在施工。
5. **代码块标记**：为所有命令添加了语法高亮标识 (`bash` / `text`)，避免全篇灰色代码块的单调。

```
