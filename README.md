# 🎯 Target

![Platform: Cross-platform](https://img.shields.io/badge/Platform-Win%20%7C%20Mac%20%7C%20Linux%20%7C%20iOS%20%7C%20Android-lightgrey.svg)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.47.0-02569B?logo=flutter)](https://flutter.dev/)

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
*   🎨 **跨平台自适应 UI**：内置中英双语（i18n），持久化存储（`SharedPreferences`）个性化主题与代理设置，自适应桌面端宽屏侧栏与移动端底部导航。

---

## 🚧 当前限制与已知问题

*   **流量与连接看板**：已通过 `TargetLibGateway` 订阅实时流量与连接数据；TargetLib 不可用或未运行时，页面会显示暂无实时快照。
*   **规则集刷新**：`refreshRuleSets()` 当前为空实现（固定返回 `0`）。
*   **构建与打包**：
    *   **Windows**：安装包暂无签名；Inno Setup 负责应用文件、TargetLib 服务注册、启动与卸载。
    *   **Android / iOS**：Android 仅使用 debug 签名；iOS CI 依赖 `--no-codesign`，无法直接作为正式 Release。
*   **CI 工作流**：`.github/workflows/build.yml` 定义了 TargetLib 与 Target 的多平台构建，并依赖 TargetLib 仓库提供的构建脚本和产物；任一外部依赖构建失败都会使对应平台任务失败。

---

## 🖥 平台支持状态

| 平台 | 运行模式 | 当前进度与现状 |
| :--- | :--- | :--- |
| **Windows** | 桌面服务 | ✅ 已接入服务安装、检测/启动及 Inno Setup 打包脚本。**支持最完善**，正式安装包仍未签名。 |
| **Linux** | 桌面服务 | 🚧 Flutter runner、TargetLib 服务打包与启动能力已接入；正式发布仍需在目标环境验证依赖。 |
| **macOS** | 桌面服务 | 🚧 已接入 macOS runner 与 Release 打包流程；正式分发仍需解决苹果签名、公证及 TargetLib 运行时交付。 |
| **Android** | 移动 VPN | 🚧 已接入移动 VPN/TUN 运行路径并在启动时请求 VPN 权限；当前 CI 产物为 debug APK，Release 签名待配置。 |
| **iOS**     | 移动 VPN | 🚧 已配置 iOS 应用与移动 VPN 运行路径；CI 使用 `--no-codesign`，尚无可直接发布的签名配置。 |

> *注：上述状态仅代表当前代码库进度，并不意味着所有平台均已通过严苛的端到端测试。*

---

## 🏗 架构与结构

### 目录结构
```text
Target/
├── lib/
│   ├── app/             # 应用入口和路由
│   ├── core/            # TargetLib 网关、平台底层能力、日志、主题、通用组件
│   ├── data/            # 数据模型：应用配置与运行时数据模型
│   └── features/        # 10 个业务模块：connections/home/logs/maps/profiles/proxies/rules/settings/subscriptions/traffic
├── assets/              # 静态资源：应用图标、服务图标和世界地图拓扑数据
├── test/                # 单元测试与组件级测试
├── tool/                # 开发者工具：TargetLib 调试脚本
├── scripts/             # 构建打包：CI/本地共用的 PowerShell 脚本与 Inno Setup 配置
└── .github/workflows/   # 持续集成：多平台自动构建工作流

```

### 核心调用链路

界面层完全解耦，不直接依赖底层的 protobuf 类型。数据流向清晰单向：

```text
Flutter UI
 └─> Riverpod Notifier (状态管理)
      └─> CoreGateway（含订阅操作） (业务网关)
           └─> TargetLibGateway (底层服务抽象)
                └─> TargetLib Flutter Package (核心 SDK)
                     └─> 本地认证 gRPC 命令服务
                          └─> 🚀 sing-box 代理引擎

```

---

## 🛠 开发指南

### 环境要求

* **Flutter**: `>=3.47.0` (同时要求 Dart `>=3.12.2 <4.0.0`)
* **Go**: 用于本地构建 TargetLib 核心服务
* **TargetLib 源码**: 需与本仓库处于**同级目录**（`pubspec.yaml` 强依赖 `../TargetLib/flutter` 路径）
* 对应目标平台的原生构建工具链 (Visual Studio / Xcode / Android Studio 等)
* **Inno Setup 6+**: 用于生成 Windows 安装包

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

构建脚本会在平台目录缺失时自动执行 `flutter create`，并用 `assets/TargetAppIcon.png` 更新 Android、iOS、macOS 和 Windows 图标。仅需更新图标时运行：

```powershell
.\scripts\generate-icons.ps1
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

