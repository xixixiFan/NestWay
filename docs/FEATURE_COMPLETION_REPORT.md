# NestWay（栖途）功能完成度分析报告

**日期：** 2026-05-16
**分支：** feature/real-device-test
**项目定位：** 女性独旅安全 Flutter App，Supabase 后端

---

## 一、整体架构

```
Flutter App (Provider 状态管理)
    ├── Supabase (PostgreSQL + Auth)
    │   ├── 4 张数据表
    │   └── 手机验证码登录
    ├── DeepSeek AI (城市安全分析)
    ├── 高德地图 (位置分享 URL)
    └── Android 原生 MethodChannel (拨打电话)
```

**路由总数：** 12 条命名路由
**后端服务：** 纯 Supabase BaaS，无独立后端服务

---

## 二、前端页面完成度

### 2.1 核心功能页面

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **HomePage** | `/` | 90% | Logo、城市安全状态、虚拟护送入口按钮、底部导航栏 |
| **LoginPage** | `/login` | 85% | 手机号+验证码登录，Supabase Auth 对接完成。**缺：** 未设为初始路由，App 启动跳过登录 |
| **SosPage** | `/sos` | 85% | 三大风险卡片（报警/位置共享/安全视频）。**缺：** `_onSosTriggered()` 方法已实现但未绑定 UI，实际发送 SMS 为模拟 |
| **SendSosMessagePage** | `/send_sos_message` | 60% | UI 完整（收件人选择+消息编辑）。**缺：** 发送动作为 `Future.delayed` 模拟，无真实 SMS API；位置和昵称硬编码 |
| **EmergencyContactsPage** | `/emergency_contacts` | 95% | 完整 CRUD，Supabase 对接。增删改查全部可用 |
| **SosHistoryPage** | `/sos_history` | 95% | 从 Supabase `sos_logs` 表拉取历史，下拉刷新，类型图标区分 |

### 2.2 虚拟护送模块

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **EscortPage** | `/escort` | 65% | 出发地/目的地/ETA 设置。**缺：** 出发地刷新按钮无操作；联系人使用 mock 数据而非真实 Provider |
| **ProgressPage** | `/escort_progress` | 70% | 倒计时器、路线展示、安全打卡按钮。**缺：** 出发地/目的地硬编码；联系人拨打按钮无操作；倒计时纯客户端无后端 |
| **SuccessPage** | `/success` | 50% | 护送完成确认页。**缺：** "继续护送"/"结束护送"按钮均为空操作；通知发送为假逻辑 |
| **TimeoutPage** | `/timeout` | 60% | 超时警告页，含"我很安全"/"需要帮助"按钮。**缺：** 倒计时为静态文字 "1:45" 而非真实计时器；自动通知未实现 |

### 2.3 安全与资料

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **SafetyPage** | `/safety` | **5%** | 仅显示 "安全页面" 文字，完全是占位符 |
| **DestinationSafetyPage** | 未注册 | **90%** | DeepSeek AI 城市安全分析完整实现。**缺：** 未注册到路由表，无法通过导航访问 |
| **ProfilePage** | `/profile` | 75% | 用户信息卡片+紧急联系人列表。**缺：** 用户数据来自 mock 而非 Supabase；退出登录按钮无点击处理 |

---

## 三、后端与数据层完成度

### 3.1 数据库（Supabase PostgreSQL）

| 表名 | 记录数 | 完成度 | 说明 |
|------|--------|--------|------|
| `users` | 1 | 90% | 用户表结构完整。**缺：** 无 avatar 上传；注册后手机号唯一约束正常 |
| `emergency_contacts` | 3 | 95% | 完整 CRUD，sort_order 自增。**缺：** user_id 在代码中硬编码为 1 |
| `sos_logs` | 3 | 90% | SOS 事件记录完整。**缺：** 插入时 user_id 硬编码为 1 |
| `escort_tasks` | **0** | **30%** | 表结构存在但无任何数据。**缺：** 无 CRUD Service 方法，无 UI 对接，无模拟数据 |

### 3.2 RLS 安全策略

**当前状态：开发模式 — 所有表使用 `USING (true)` 全放行策略**

生产环境需切换为基于 `auth.uid()` 的严格用户隔离策略（SQL 已编写但未启用）。

### 3.3 Service 层

| Service | 方法数 | 完成度 | 说明 |
|---------|--------|--------|------|
| **SupabaseService** | 2 | 90% | 单例初始化。**缺：** URL/Key 硬编码在源码中（非 .env 读取） |
| **SosService** | 11 | 85% | 核心服务。**缺：** `getCurrentLocation()` 对应的原生端 MethodChannel `com.nestway/location` 未实现 |
| **ContactsProvider** | 5 | 95% | ChangeNotifier 状态管理完整 |

### 3.4 外部 API 集成

| API | 用途 | 完成度 | 说明 |
|-----|------|--------|------|
| **Supabase REST/DB** | 数据存储+查询 | **100%** | 读写正常 |
| **Supabase Auth (Phone OTP)** | 手机验证码登录 | **90%** | 代码完整，需 Supabase 后台开启 Phone Auth + Twilio 配置 |
| **DeepSeek AI** | 城市安全分析 | **95%** | API 调用完整，JSON 解析正常。需 `--dart-define` 传入 Key |
| **高德地图** | 位置分享 URL | **100%** | URL 生成逻辑完整，无需 API Key |
| **SMS 发送** | 紧急短信通知 | **0%** | 完全模拟，无真实集成 |

### 3.5 原生平台（Android）

| 功能 | 完成度 | 说明 |
|------|--------|------|
| 拨打电话 (CALL_PHONE) | **100%** | `com.nestway/phone` MethodChannel 完整实现 |
| 打开拨号盘 (ACTION_DIAL) | **100%** | 无需权限 |
| 获取位置 (ACCESS_FINE_LOCATION) | **0%** | `com.nestway/location` 有 Flutter 端调用，无原生实现 |
| AndroidManifest 权限声明 | **0%** | CALL_PHONE、ACCESS_FINE_LOCATION、INTERNET 均未声明 |
| Release 签名 | **0%** | 使用 debug 签名占位 |

---

## 四、未使用的组件和死代码

以下 widgets 已实现但从未在页面中使用：

| 组件 | 用途 |
|------|------|
| `PrimaryButton` | 大圆形黄色按钮 |
| `SecondaryButton` | 小圆角矩形按钮 |
| `SosButton` | 长按 SOS 按钮（含倒计时动画） |
| `CountdownOverlay` | 全屏倒计时叠加层（3-2-1） |

以下 mock 数据文件已定义但未被导入使用：
- `mock_city_safety.dart`（7 个城市安全数据）
- `mock_videos.dart`（2 个视频条目）
- `mock_sos_logs.dart`（3 条 SOS 历史，改用 Supabase 真实数据）

---

## 五、关键缺失与风险

### 5.1 阻塞性问题

1. **无认证守卫** — App 启动直接进入首页，登录页存在但被绕过；所有 DB 操作使用 `user_id=1`
2. **位置获取不可用** — 原生 MethodChannel 缺失，所有位置功能降级为 hardcode 或 null
3. **SMS 发送为假实现** — 核心安全功能的核心环节是 `Future.delayed(800ms)`

### 5.2 功能缺口

4. **`SafetyPage` 为空白占位** — `/safety` 路由指向一个只有 "安全页面" 文字的页面
5. **`DestinationSafetyPage` 不可达** — AI 城市分析页已完整实现但未注册路由
6. **`escort_tasks` 表完全未对接** — 护送任务没有后端读写
7. **ProfilePage 用户数据来自 mock** — 不从 Supabase `users` 表读取
8. **退出登录不可用** — 按钮无点击处理
9. **护送流程多处硬编码** — 联系人、位置、昵称、倒计时均为静态值

### 5.3 安全隐患

10. **Supabase Key 硬编码在源码** — `supabase_service.dart` 中明文存储
11. **RLS 处于全放行模式** — 任何客户端可读写任意用户数据
12. **DeepSeek API Key 前端直传** — API Key 通过 `--dart-define` 传入后在前端直接调用，暴露给客户端
13. **`.env` 文件未加入 `.gitignore`** — 凭据可能被提交

---

## 六、完成度总览

| 模块 | 完成度 | 状态 |
|------|--------|------|
| 紧急联系人 CRUD | 95% | 基本完成 |
| SOS 历史记录 | 95% | 基本完成 |
| SOS 紧急报警（拨打 110） | 90% | 基本完成 |
| 手机验证码登录 | 85% | 已实现，未接入启动流程 |
| SOS 短信发送 | 60% | 发送为模拟 |
| 虚拟护送 — 设置 | 65% | UI 完整，数据来源待对接 |
| 虚拟护送 — 进行中 | 70% | 倒计时可用，多处占位 |
| 虚拟护送 — 完成/超时 | 55% | 按钮操作为空 |
| AI 城市安全分析 | 90% | 完整但不可达（路由未注册） |
| 安全页面 | 5% | 占位符 |
| 个人资料 | 75% | 用户数据用 mock |
| 数据库 | 75% | escort_tasks 表未对接，RLS 未启用 |
| 原生平台（Android） | 35% | 仅拨号功能可用 |
| **项目整体** | **~65%** | 核心 SOS 链路可用，护送模块骨架完成，安全/资料模块待开发 |

---

## 七、建议开发优先级

1. **认证守卫** — 将 LoginPage 设为初始路由，用 Supabase `onAuthStateChange` 控制导航
2. **修复 DestinationSafetyPage 路由** — 替换 `/safety` 占位页
3. **完善 escort_tasks 后端对接** — 实现护送开始/打卡/超时的数据库读写
4. **真实 SMS 集成** — 接入 Twilio 或阿里云短信服务
5. **原生位置获取** — 实现 `com.nestway/location` MethodChannel
6. **启用 RLS** — 切换为严格用户隔离策略
7. **清理死代码** — 移除未使用的 mock 文件和 widget
