# Smart Connect：TargetLib 代码能力核对

核对日期：2026-09-12。

核对对象是 `pubspec.yaml` 实际依赖的 `../TargetLib/flutter` 及其 Go 核心，绝对路径为 `C:/Users/kangj/Documents/Project/TargetLib`，不是 `targetlib-inspect` 副本。基线 HEAD 为 `741167f7a3683a016badcede4f652a4e785977d0`，包含核对时已存在的大量未提交修改和新增文件。以下结论仅代表本地工作树，不代表已提交版本、已发布 SDK 或已安装服务的能力。

## 1. 结论

此前列出的七类核心能力均已有实现基础；多订阅节点池、多 selector、域名路由、绑定 CRUD、配置事务、状态查询、服务探测、质量评分和事件流不是仅有 proto 声明。当前可以开始接入服务级代理流程，无需从零新增整套接口。

尚不能把完整需求视为完成：服务级 Direct 被校验拒绝；完整服务策略、用户偏好及绑定选择审计字段缺失；Target 应用尚未接通大部分 SDK 能力。真实流量分流及真实机场/目标服务探测仍需端到端验收。

## 2. 核心能力与代码依据

下表代码路径相对于 `../TargetLib`，行号对应本次工作树。

| 能力 | 结论 | 代码依据与边界 |
|---|---|---|
| 多订阅统一节点池 | 已有 | `subscriptions/node_pool.go:17` 汇总已启用订阅；`manager/smart_connect.go:200` 实现 `GetNodePool`。返回来源、协议、声明地区、节点阶段和池 revision。稳定 ID 通过 `ProfileNode.tag` 返回，并非独立 `node_id` 字段。 |
| 稳定节点身份 | 已有 | `profile/identity.go:12` 的 `WithSource` 对订阅 ID 和规范化连接参数做哈希，排除显示 tag 和顺序；同一订阅内同连接参数去重，改显示名不改变身份。连接参数或订阅 ID 改变会生成新身份。 |
| 多 selector 与域名分流 | 已有，Direct 不完整 | `config/runtime_validation.go:10` 校验每服务独立 selector；`config/build.go:170` 生成域名后缀规则，更具体域名优先；`:207` 生成共享节点 outbound 和独立 selector。全局 Direct 模式不应用服务路由。 |
| 服务绑定 CRUD | 已有，元数据部分支持 | `manager/smart_connect.go:213`、`:218`、`:266` 实现列表、应用、移除。应用要求已有匹配路由且节点属于 selector，并启用路由；移除绑定会禁用相应路由。不是“仅传 serviceId/nodeId 就能创建完整服务”。 |
| 绑定和运行配置持久化 | 已有 | `manager/runtime_config_store.go:34` 原子保存配置和节点快照；`manager/manager.go:99`、`:161` 恢复；`manager/smart_connect.go:77` 启动保存的快照。绑定过期标记待评估，不自动换节点。 |
| 多服务一次提交 | 已有 | `manager/runtime_config.go:59` 的 `UpdateRuntimeConfig` 接收完整 `RuntimeModel`，包含 selectors/routes/bindings。请求必须带 settings；model 缺省则保留原模型，存在则整体替换。 |
| 配置事务与回滚 | 已有 | `manager/smart_connect.go:34` 校验 `expected_revision`；`:137` 执行 VALIDATING → BUILDING → APPLYING → READY/FAILED。加载或持久化失败尝试恢复旧配置；回滚自身失败返回 DataLoss，不能承诺绝对无损。重载可能关闭旧连接，不是无中断热切换。 |
| 实际运行状态 | 已有，但不是健康证明 | `manager/smart_connect.go:369` 查询实际 selector 选择，并结合已应用 revision 判断 effective。路由 effective 来自配置与运行 selector，不是逐条读回 sing-box 路由或实际流量验证。`node_available` 仅表示池中存在可构建节点，服务健康要结合探测结果。 |
| 运行时事件 | 已有 | `manager/smart_events.go:40` 首次发送快照，后续发送配置、绑定、节点池和探测事件；慢消费者断开后需重连。`:76` 通过订阅事件及一秒轮询观察状态变化。 |
| 指定节点服务探测 | 已有 | `manager/smart_probe.go:36` 创建独立探测实例并直接调用指定 outbound；`:72` 实现流式 `ProbeService`，通过 RPC context 取消，不修改当前绑定。每请求最多 256 节点、4 并发、5 次尝试。 |
| 地区、错误阶段和质量 | 已有通用机制 | `manager/smart_probe.go:252` 进行 HTTP/内容/地区检查，区分 DNS/TCP/TLS/HTTP/AUTH/TIMEOUT 等。出口地区需配置 egress URL；服务地区可读指定响应头。不是内置所有网站的解锁判定；每服务探测定义只有一个目标 URL。 |
| 历史与评分 | 已有基础实现 | `manager/smart_quality.go:245` 查询历史；`:304` 排除未测、过期、策略变更、失败及不符合丢包要求的结果；`:328` 综合成功率、平均延迟、抖动及可用的 UDP 丢包数据排序。EvaluateService 只读取已有结果，不触发探测或应用绑定。 |
| 禁止自动 fallback | 主要流程已有保障 | 探测和评估不应用绑定；`manager/smart_events.go:76` 观察订阅变化但不切换配置；`subscriptions/manager.go:432` 更新失败保存错误及旧 profile。过期或移除节点仅标记待评估。普通配置仍生成独立 urltest 做后台测速，但它不在服务 selector 的成员中，不承担服务故障转移。 |
| 能力查询 | 核心及生成客户端已有 | `manager/manager.go:216` 返回 smart_connect/service_probes/runtime_events；`api/TargetLib/targetlib.proto:97` 定义字段。尚无 service_direct 等细分标志；Flutter Runtime/Connection 无便捷 getCapabilities 方法，生成的 gRPC client 已有。 |

## 3. 需要补齐的契约

### 必须在 TargetLib 补齐

1. **服务级 Direct。** `config/runtime_validation.go` 只允许全局 proxy selector 包含 direct，服务路由又禁止使用 proxy；`config/build.go` 的独立 selector 成员也只接受节点。因此不能用现有服务绑定表达直连。建议明确支持服务 direct 目标，或允许独立服务 selector 选择 direct，并同步校验、状态语义和测试。

### 必须实现，但可以由 Target 应用持有

2. **完整服务策略与节点偏好。** 当前 proto 没有完整 ServicePolicy，没有首选地区、允许订阅、排除节点、标签、收藏、节点启停、订阅优先级和 stickyDuration 模型。ServiceProbe 的 allowed_countries 只覆盖地区硬约束，selector.node_ids 可以承载应用筛选后的执行候选集。EvaluateService 遍历整个启用节点池，不读取服务 selector 的成员限制；客户端不能直接采用其第一名，必须再执行完整策略筛选。

3. **选择审计。** `ServiceBinding` 仅有 service_id、selector_tag、node_id、revision、expires_at；缺少 selectedAt、当时的 score、selectionReason、触发来源和策略版本。当前评分/诊断快照不能还原绑定创建时的完整选择依据。可由应用持久化；若要求核心权威记录或多客户端一致性，则扩展核心契约。

4. **策略修改与应用前检查。** 探测定义变化可使质量失效，但域名/用户偏好等完整策略变更尚无统一 revision 关联。ApplyServiceBinding 校验结构和节点成员关系，不强制检查探测资格、地区或评估版本。自动选择流程需校验最新策略、探测有效期及运行配置版本，再显式应用；手动选择的检查规则也应明确。

5. **多个服务探测目标。** 需求示例含 chatgpt.com 和 openai.com，当前一个 service_id 只保存一个 ServiceProbe URL。若要求多目标共同通过，需由应用编排多个探测定义并汇总，或扩展核心探测模型；当前接口没有服务级多目标聚合。

### SDK/接入完善

6. 增加 Runtime 层 getCapabilities 便捷封装并在应用接入；后续能力演进可增加服务直连、策略等细分标志。现有生成客户端可以直接调用，不需要重新创建核心能力查询 RPC。

7. Flutter SDK 已封装更新完整模型、绑定 CRUD、探测定义、流式探测、质量历史、评估、实际状态、运行时事件和策略导入导出，见 `flutter/lib/src/runtime/target_lib_connection.dart:115` 及 `target_lib_runtime.dart:106`。策略导入导出仅含探测定义，不含完整服务策略、运行绑定或跨设备质量同步。

## 4. Target 应用当前接入程度

- `lib/core/runtime/core_gateway.dart:43` 仅暴露 Smart Connect 的节点池、绑定列表和诊断查询。
- `lib/core/runtime/target_lib_gateway.dart:314` 转发上述查询；应用的 updateRuntimeConfig 仍只接受基础 RuntimeSettings，不能提交完整 RuntimeModel。
- `lib/features/smart_connect/presentation/smart_connect_page.dart:18` 只加载节点池和绑定列表并显示 toString 文本；尚无策略编辑、绑定应用、探测取消、评分交互、运行事件订阅或实际状态总览。
- 因此“TargetLib 已有”与“Target 已可用”必须分开验收。当前首要接入工作是拓展 Gateway、建立策略/绑定状态管理和完成服务操作界面。

## 5. 验证结果与限制

- 执行 `go test ./config ./profile ./subscriptions ./manager`：前三包通过，manager 因缺少 with_clash_api 编译标签失败。
- 按失败信息补充标签后执行 `go test -tags with_clash_api ./config ./profile ./subscriptions ./manager`：四个包全部通过。
- 执行 `flutter analyze lib/src/runtime/target_lib_runtime.dart lib/src/runtime/target_lib_connection.dart`：通过，无问题。
- 现有测试包括独立 selector/域名优先级、指定 outbound 探测、错误阶段、质量持久化/过期、取消和并发、gRPC 探测/事件、绑定过期/节点移除不切换、保存失败回滚、UDP 丢包和策略导入。参见 `config/smart_connect_test.go`、`manager/smart_connect_test.go`。
- 不少测试使用本地 HTTP/TLS 服务或注入运行时替身；本次未验证真实机场节点、真实目标服务的地区解锁、多服务真实流量出口，也未验证已安装二进制与当前工作树一致。
- 本次只新增此核对文档，没有修改业务实现或覆盖 TargetLib 原有未提交改动。

## 6. 建议执行顺序

1. TargetLib 补齐服务 Direct 的表达、执行和状态契约。
2. Target 接通现有 SDK：能力查询 → 节点池 → 提交服务模型 → 应用绑定 → 运行状态及事件。
3. Target 建立完整策略和选择记录，再接通探测 → 筛选 → 评分展示 → 显式应用；评估不能直接等同于应用。
4. 使用实际构建的 TargetLib 做多服务出口、失败不切换、配置回滚和重启恢复的端到端验收。
