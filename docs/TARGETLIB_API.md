# TargetLib gRPC API

Target 使用 TargetLib 提供的 gRPC 接口进行代理控制。完整协议定义见 [TargetLib/api/TargetLib/targetlib.proto](../../TargetLib/api/TargetLib/targetlib.proto)。

---

## 接口分层

| 层级 | 功能 | RPC 数量 | 对应 sing-box 模式 |
| --- | --- | --- | --- |
| **Layer 1: 基础代理** | 订阅、切换、启停 | 20 个 | route_mode = DIRECT / ALL |
| **Layer 2: 规则分流** | 域名规则管理 | 4 个 | route_mode = RULE |

---

## Layer 1: 核心代理

### 生命周期

| RPC | 类型 | 说明 |
| --- | --- | --- |
| `Start` | 命令 | 启动 sing-box；重复调用返回 `FAILED_PRECONDITION` |
| `Stop` | 命令 | 停止 sing-box |
| `Restart` | 命令 | 重启（热加载配置）|
| `GetState` | 查询 | 运行状态：idle/starting/running/stopping/failed |
| `SubscribeState` | 流 | 监听状态变化 |
| `SubscribeLogs` | 流 | 日志流（仅 ERROR+）|
| `SubscribeTraffic` | 流 | 流量统计（间隔 250-5000ms）|

### 订阅管理

| RPC | 类型 | 说明 |
| --- | --- | --- |
| `ListSubscriptions` | 查询 | 列出所有订阅 |
| `GetSubscription` | 查询 | 查询单个订阅 |
| `AddSubscription` | 命令 | 添加订阅；`update_now=true` 失败则回滚 |
| `RemoveSubscription` | 命令 | 删除订阅 |
| `UpdateSubscription` | 命令 | 手动更新；返回 changed/not_modified |
| `RenameSubscription` | 命令 | 重命名 |
| `SetSubscriptionEnabled` | 命令 | 启用/禁用；禁用的订阅不进节点池 |
| `ConfigureSubscriptionUpdates` | 命令 | 配置自动更新（最小间隔 5 分钟）|
| `GetNodePool` | 查询 | 获取节点池（所有启用订阅的节点）|
| `GetResolvedEndpoints` | 查询 | 节点地址列表（用于 VPN 排除）|
| `SubscribeSubscriptionEvents` | 流 | 订阅事件：added/updated/removed |

**NodePool 结构：**
```protobuf
message NodePool {
  string revision = 1;
  repeated ProfileNode nodes = 2;
}

message ProfileNode {
  string tag = 1;              // node_id（用于 SelectNode）
  string subscription_id = 10;
  string name = 2;
  string type = 3;
  string server = 4;
  int32 port = 5;
  string country_code = 9;     // "HK", "US" 等
  ProfileNodePhase phase = 7;  // ready/failed
  string error_message = 8;
}
```

### 节点切换

```protobuf
rpc SelectNode(SelectNodeRequest) returns (SelectNodeResponse);

message SelectNodeRequest {
  string node_id = 1;  // 来自 NodePool 的 node.tag
}

message SelectNodeResponse {
  string node_id = 1;
  string node_name = 2;
  bool applied_immediately = 3;  // true: live select; false: 已保存
  string error_message = 4;
}
```

**行为：**
- 运行中：live select 立即返回
- 未运行：保存配置，下次启动生效
- 失败自动回滚

**示例：**
```typescript
const response = await client.selectNode({ nodeId: 'hk-node-01' });
showToast(`已切换到 ${response.nodeName}`);
```

### 状态查询

```protobuf
rpc GetProxyStatus(Empty) returns (ProxyStatus);

message ProxyStatus {
  ServiceStateType service_state = 1;
  string selected_node_id = 2;
  string selected_node_name = 3;
  string actual_node_id = 4;       // 运行时读回
  bool effective = 5;               // selected == actual
  int64 selected_at_unix_ms = 6;
  bool node_available = 7;
  string unavailable_reason = 8;
}
```

### 配置管理

| RPC | 类型 | 说明 |
| --- | --- | --- |
| `GetRuntimeConfig` | 查询 | 运行时配置（settings + selectors + routes）|
| `UpdateRuntimeConfig` | 命令 | 更新 settings（listen_address, proxy_mode 等）|

---

## Layer 2: 规则分流

**本质：** sing-box 的 `route_mode = RULE` 管理接口。核心提供内置大陆直连（cn.srs），Layer 2 允许动态添加自定义域名规则。

**使用场景：**
- 大陆直连，国外走代理（内置）
- Netflix 走美国节点
- ChatGPT 走特定节点
- 其他流量走默认代理节点

```protobuf
rpc UpsertRoute(UpsertRouteRequest) returns (RouteInfo);
rpc DeleteRoute(DeleteRouteRequest) returns (Empty);
rpc ListRoutes(Empty) returns (RouteList);
rpc SelectRouteNode(SelectRouteNodeRequest) returns (SelectNodeResponse);

message UpsertRouteRequest {
  string service_id = 1;        // "netflix"
  string display_name = 2;      // "Netflix 专线"
  repeated string domains = 3;  // ["netflix.com", "nflxvideo.net"]
  string node_id = 4;
  bool enabled = 5;
}

message RouteInfo {
  string service_id = 1;
  string display_name = 2;
  repeated string domains = 3;
  string selector_tag = 4;      // 核心分配（内部使用）
  string current_node_id = 5;
  string current_node_name = 6;
  bool enabled = 7;
  bool effective = 8;           // running + enabled
}
```

**工作原理：**
```
route_mode = RULE 时：
1. 大陆域名/IP → direct（内置 cn.srs）
2. UpsertRoute 创建的规则 → 对应 selector → 指定节点
3. 其他流量 → proxy selector → 默认节点（SelectNode）
```

**示例：**
```typescript
// 1. 设置为规则分流模式
await client.updateRuntimeConfig({
  settings: { routeMode: 'RULE' }
});

// 2. 创建 Netflix 规则
await client.upsertRoute({
  serviceId: 'netflix',
  displayName: 'Netflix 专线',
  domains: ['netflix.com', 'nflxvideo.net'],
  nodeId: 'us-node-01',
  enabled: true,
});

// 3. 切换 Netflix 规则的节点
await client.selectRouteNode({
  serviceId: 'netflix',
  nodeId: 'us-node-02',
});

// 4. 切换默认代理节点（其他流量）
await client.selectNode({ nodeId: 'hk-node-01' });
```

**效果：**
- 访问 `netflix.com` → 走美国节点 `us-node-02`
- 访问国内网站 → 直连
- 访问其他国外网站 → 走香港节点 `hk-node-01`

---

## Route Mode 说明

| 模式 | 说明 | 适用层级 |
| --- | --- | --- |
| `DIRECT` | 全部直连，不走代理 | Layer 1 |
| `ALL` | 全部走代理 | Layer 1（SelectNode 选择节点）|
| `RULE` | 规则分流 | Layer 1 + Layer 2 |

**RULE 模式流量分配：**
```
请求域名 example.com
  ↓
匹配 UpsertRoute 创建的规则？
  ├─ 是 → 走规则指定的节点
  └─ 否 → 匹配大陆规则（cn.srs）？
           ├─ 是 → 直连
           └─ 否 → 走默认代理节点（SelectNode）
```

---

## 传输与安全

### 端点

- TCP: `127.0.0.1:19090`
- Unix Socket: `<basePath>/targetlib.sock`

### 认证

**需要 `Authorization: Bearer <token>` 的 RPC：**
- Layer 2: `UpsertRoute`, `DeleteRoute`, `SelectRouteNode`
- 配置: `UpdateRuntimeConfig`

Token 存储在 `<basePath>/control.token`。

---

## 错误处理

| gRPC Code | 场景 | 客户端处理 |
| --- | --- | --- |
| `INVALID_ARGUMENT` | 参数错误 | 显示错误 |
| `NOT_FOUND` | 节点/订阅/路由不存在 | 刷新列表 |
| `FAILED_PRECONDITION` | 前置条件失败 | 显示当前状态 |
| `UNAVAILABLE` | 服务不可用 | 重连 |
| `UNAUTHENTICATED` | Token 无效 | 重新读取 token |
| `INTERNAL` | 内部错误 | 显示错误日志入口 |

**常见错误消息：**
- `"node not found"`: 节点不在池中
- `"service is already running"`: 重复启动
- `"live select failed"`: 运行时切换失败（已回滚）

---

## Target 典型使用流程

### 基础流程
```
1. 用户打开 Target
2. 添加订阅 → GetNodePool 获取节点列表
3. 点击节点 → SelectNode
4. 点击启动 → Start
5. SubscribeState 监听状态
```

### 分流场景
```
1. UpdateRuntimeConfig 切换到 RULE 模式
2. UpsertRoute 创建 Netflix 规则
3. SelectRouteNode 为 Netflix 选节点
4. SelectNode 为默认流量选节点
5. ListRoutes 查看所有规则状态
```
