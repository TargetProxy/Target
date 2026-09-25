# Smart Connect 实验框架交付说明

## 2026-09-24：收敛到 intent 单一路径

删除 Dart 侧的旧运行模型路径和本地评分：`TargetSmartConnectRepository`、`selectSmartNode`、
`smartCandidateExclusion`、`policyForDomain` 及仅供它们使用的 `SmartNode` 质量字段
（`probePassed`/`successRate`/`packetLoss`/`policyRevision`/`expiresAt`/`serviceRegion`）。
`SmartConnectRepository` 保留为测试替身用的接缝，唯一实现是 `IntentSmartConnectRepository`。
`SmartRuntimeGateway` 收窄到 `smartCapabilities`/`smartConfig`，探测、事件、质量历史和
`updateSmartModel` 一并移除。

同时删除已被焊死为 true 的总开关残留：`AppSettings.smartConnectEnabled`、`SettingsNotifier`
里的强制覆写、`SmartConnectNotifier.setEnabled`/`enabled`/`initialize`/`prepareForStart`、
两个 repository 的 `disable()`、`SmartPolicyStore` 的运行配置所有权标记，以及
`node_pool_page.dart` 中永远为真的判断。Smart Connect 现在是应用唯一的服务路由路径，
不再有"关闭后回到普通模式"的语义。

## 2026-09-19：TargetLib intent API 接入

实际依赖的 `../TargetLib` 支持 `smart_connect_intent_api` 时，Target 现在通过核心持久化服务策略和节点偏好，请求评估并审批 proposal（或显式 Force Direct/节点），等待持久化 operation 的最终状态，再读取核心的实际绑定。该路径不再由 Dart 拼装运行模型或决定最终评分。核心评估会在质量缺失/过期时进行指定节点探测，多个目标必须全部通过；Direct 不依赖探测。首选地区是评分偏好，硬性地区/订阅及节点排除在核心检查。

部署时必须用这份 `../TargetLib` 源码重新构建并安装服务；仅重建 Flutter UI 不会替换系统服务。当前 intent 契约没有取消正在运行的评估的 RPC，UI 取消只放弃本次结果并在提案出现后拒绝它。核心也没有“必需节点标签”策略字段：配置此限制时应用明确拒绝同步，不会绕过。离线编辑的本地策略会在下次评估时同步到核心；策略导入仍是本地操作，需逐项评估或编辑后同步。真实机场和目标服务的地区解锁尚未做端到端验收。

日期：2026-09-13。

本说明对应 Target 当前工作树，以及实际路径依赖 `../TargetLib/flutter` 和 `../TargetLib` Go 核心。`smart-connect-capability-audit.md` 是早期能力核对，不能替代本次实现状态。

## 使用流程

1. 在现有订阅页面添加并启用订阅。
2. 打开 Smart Connect。功能常开，没有总开关；打开页面只查询能力与运行状态，不自动切换出口。
3. 添加自定义服务，或编辑 ChatGPT / Disney+ / YouTube / Direct 模板。配置域名、地区、订阅、排除节点、标签和探测目标。
4. 点击“Re-evaluate”。每个候选节点的所有服务目标都必须通过；评估不会改变当前绑定。
5. 查看分数、地区、最近测试时间和排除原因；点击“Apply result”或“Use node”才提交服务路由。Manual 策略必须明确选择节点。
6. 查看核心返回的 Effective / Not effective 状态。配置已保存不等于运行中，也不等于服务健康。
7. 要撤销某个服务的路由，使用该服务的 Remove；核心删除对应 selector、路由和绑定，本地策略、偏好与审计保留。

`Allow evaluation for this policy` 控制后续评估资格；编辑策略会令现有绑定待评估，不会后台更换出口。要撤销现有服务路由，使用 Remove。

## 模块边界

- `domain/smart_connect_models.dart`：完整服务策略、探测目标、节点偏好、候选过滤、有效期校验、地区优先和综合评分。
- `domain/smart_runtime_models.dart`：评估快照、绑定和实际运行状态的应用模型。
- `data/smart_policy_store.dart`：独立持久化键保存策略、稳定节点 ID 对应的偏好、订阅优先级、结构化审计和运行配置所有权。
- `data/smart_connect_repository.dart`：唯一了解 protobuf 的功能数据层；多目标探测、256 节点分批、取消流、原子运行模型提交、实际状态和历史查询。
- `application/smart_policy_notifier.dart`：串行持久化、导入校验和失败时保留原策略。
- `application/smart_connect_notifier.dart`：可选开关、显式评估/应用、取消代次、绑定保留、状态事件和结构化日志。
- `presentation/`：服务模板、策略编辑、手动节点选择、节点偏好、历史、导入导出和诊断导出。导出提供可复制的 JSON，不包含订阅凭证的诊断数据。
- `core/runtime/smart_runtime_gateway.dart`：可选 native 能力接口，独立于普通代理操作；TargetLibGateway 使用原有连接并检查配置 revision。

应用功能路径均相对于 `lib/features/smart_connect/`，其他路径相对于 Target 根目录。

## 验收证据

| 需求 | 实现与验证 |
| --- | --- |
| FR-001 多订阅 | 复用现有订阅管理；核心启用订阅节点池；已有 profiles/subscriptions 测试覆盖独立启停、失败保留、不自动改节点。Smart Connect 本地保存订阅优先级。 |
| FR-002 统一节点池 | 展示名称、稳定 ID、来源、协议、地区；收藏、排除、启停和标签单独持久化；核心 identity 与订阅测试覆盖稳定身份基础。 |
| FR-003 策略 | 自定义服务及四种模板；域名、允许/首选地区、订阅、节点排除、标签、Direct/Manual/Automatic；导入原子验证；策略 SHA-256 revision 使旧评估失效。 |
| FR-004 评估 | 核心指定 outbound HTTP/内容/出口地区/服务地区探测；每批最多 256 节点、4 并发、3 次尝试；所有目标共同通过；错误阶段、历史和取消。Dart 取消测试验证取消实际流且不启动下个目标。 |
| FR-005 选择 | 拒绝失败、过期、未来时间、策略变更和不符合地区的记录；实际观测优先，综合成功率、丢包、延迟及偏好；保留评分和每节点排除原因。 |
| FR-006 绑定 | 核心保存选中时间、有效期、评分、原因、策略 revision；评估/失败/取消均保留原绑定；应用必须显式触发；绑定过期不自动换节点。 |
| FR-007 运行路由 | 每服务独立 singleton selector，保留普通 proxy；原子更新整个模型并检查 revision；实际状态读取和事件流；本地真实 sing-box 流量测试验证两个服务不同出口、失败不切换和停用后普通代理接管。 |
| FR-008 可解释性 | 来源、地区、评估时间、分数、选中与排除原因、运行状态、历史及审计；多目标历史共同决定是否需要重新评估。 |
| 核心要求 | 只有 intent 路径；核心不实现 intent API 时 `smartRepositoryProvider` 抛 UnsupportedError，界面显示未支持，不回退本地评分。 |
| 持久化与恢复 | 策略、偏好、优先级和审计跨 store/container 恢复；启用状态下核心绑定与模型沿用核心持久化；串行写入及保存失败不发布未保存策略均有测试。 |
| 普通模式隔离 | 保留基础 settings、全局 selector 与外部服务模型；已有普通代理测试与核心真实流量测试共同验证。 |
| 体验与阶段四 | 测试历史、出口地区探测、可配置区域/内容检查、绑定有效期、策略模板、自定义服务及策略/诊断 JSON 导出已接入。 |

## 核心修复

在实际 `../TargetLib` 工作树补齐两处 Direct 问题：

- `manager/smart_connect.go`：Direct 是明确目标，不依赖订阅节点池和节点探测；仍检查绑定有效期。
- `config/build.go`：没有订阅节点时也生成服务级 Direct selector，避免路由引用缺失。

新增/补充核心测试：`manager/smart_direct_status_test.go`、`manager/smart_traffic_integration_test.go`、`config/service_policy_test.go`。未修改 `targetlib-inspect` 的已有修改。

## 验证结果

- `flutter analyze --no-pub`：通过，无问题；`git diff --check`：通过。
- `flutter test --no-pub`：71 项通过，其中 Smart Connect 32 项。
- `flutter build windows --debug --no-pub`：通过，输出 `build/windows/x64/runner/Debug/target.exe`。
- `go test -tags with_clash_api ./config ./profile ./subscriptions ./manager`：通过。
- UI 自动测试覆盖 360、800、1440 宽度的评估、应用与实际状态展示，以及禁用页面不调用核心。
- `TestSmartServiceTrafficIsolationAndDisable` 启动真实 sing-box mixed inbound 和两台本地 HTTP 代理节点，实际发送 HTTP 流量；重复启动相同配置后服务出口保持，失败节点不会回退到另一节点，停用规则后走普通 selector。

## 实验边界

- 本次验证使用受控本地代理和 HTTP 服务，未用真实机场及 ChatGPT/Disney+ 账号验收区域解锁。模板是可编辑探测起点；通用 HTTP 200 不等于账号或流媒体解锁成功，需要服务特定的正文、响应头与出口地区条件。
- 出口地区依赖用户明确配置的 JSON endpoint；未配置时展示声明地区，不能伪称已测得真实出口。跨目标地区冲突会排除节点。
- 评估使用核心记录的实际探测结果；不会后台探测或自动故障切换。事件只刷新状态，事件流断开时明确提示手动刷新。
- 服务路由切换由核心重载执行，可能关闭旧连接；关闭功能失败时开关保持开启并显示错误，不伪称已经恢复普通模式。
- Windows Flutter 构建不会安装/替换系统中的 TargetLib 服务。上述 Go 修复需要使用从当前 `../TargetLib` 源码构建的核心；旧核心能力不足时界面会报错，不展示虚假成功。

