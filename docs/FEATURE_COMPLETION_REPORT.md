# NestWay（栖途）功能完成度分析报告

**日期：** 2026-05-16
**分支：** feature/real-device-test（已合并 master + feature/safety-profile）
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
    ├── 高德 Flutter 地图 (amap_flutter_map)
    └── Android 原生 MethodChannel (拨打电话)
```

**路由总数：** 12 条命名路由
**后端服务：** 纯 Supabase BaaS，无独立后端服务
**已合并分支：** `master`（定位/权限/地图）、`feature/safety-profile`（安全资料/栖途品牌）

---

## 二、前端页面完成度

### 2.1 核心功能页面

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **HomePage** | `/` | 90% | 栖途品牌区+城市安全状态+虚拟护送入口按钮+三大功能卡片（SOS/护送/预警）+目的地搜索+热门目的地+底部导航栏。SOS和护送卡片可点击跳转 |
| **LoginPage** | `/login` | 85% | 手机号+验证码登录，Supabase Auth 对接完成。**缺：** 未设为初始路由，App 启动跳过登录 |
| **SosPage** | `/sos` | 85% | 三大风险卡片（报警/位置共享/安全视频）。**缺：** `_onSosTriggered()` 方法已实现但未绑定 UI，实际发送 SMS 为模拟 |
| **SendSosMessagePage** | `/send_sos_message` | 60% | UI 完整（收件人选择+消息编辑）。**缺：** 发送动作为 `Future.delayed` 模拟，无真实 SMS API；位置和昵称硬编码 |
| **EmergencyContactsPage** | `/emergency_contacts` | 95% | 完整 CRUD，Supabase 对接。增删改查全部可用 |
| **SosHistoryPage** | `/sos_history` | 95% | 从 Supabase `sos_logs` 表拉取历史，下拉刷新，类型图标区分 |

### 2.2 虚拟护送模块

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **EscortPage** | `/escort` | 65% | 出发地/目的地/ETA 设置。**缺：** 出发地刷新按钮无操作；联系人使用 mock 数据而非真实 Provider |
| **ProgressPage** | `/escort_progress` | 75% | 倒计时器、路线展示、安全打卡按钮。已接入定位服务（30s 轮询）。**缺：** 出发地/目的地硬编码；联系人拨打按钮无操作；倒计时纯客户端无后端 |
| **SuccessPage** | `/success` | 50% | 护送完成确认页。**缺：** "继续护送"/"结束护送"按钮均为空操作；通知发送为假逻辑 |
| **TimeoutPage** | `/timeout` | 60% | 超时警告页，含"我很安全"/"需要帮助"按钮。**缺：** 倒计时为静态文字 "1:45" 而非真实计时器；自动通知未实现 |

### 2.3 安全与资料

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **SafetyPage** | `/safety` | **5%** | 仅显示 "安全页面" 文字，完全是占位符 |
| **DestinationSafetyPage** | 可访问 | **90%** | DeepSeek AI 城市安全分析完整实现。首页搜索框和热门目的地可直接跳转。**缺：** 未注册到路由表 |
| **ProfilePage** | `/profile` | 80% | 用户信息卡片+紧急联系人列表（Provider+本地双数据源）。**缺：** 用户数据来自 mock 而非 Supabase；退出登录按钮无点击处理 |

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
| **LocationService** | - | **NEW** | 新增定位服务（来自 master 合并），支持 30s 轮询位置更新 |

### 3.4 外部 API 集成

| API | 用途 | 完成度 | 说明 |
|-----|------|--------|------|
| **Supabase REST/DB** | 数据存储+查询 | **100%** | 读写正常 |
| **Supabase Auth (Phone OTP)** | 手机验证码登录 | **90%** | 代码完整，需 Supabase 后台开启 Phone Auth + Twilio 配置 |
| **DeepSeek AI** | 城市安全分析 | **95%** | API 调用完整，JSON 解析正常。需 `--dart-define` 传入 Key |
| **高德地图 URL** | 位置分享 URL | **100%** | URL 生成逻辑完整，无需 API Key |
| **高德 Flutter 地图** | 地图显示 | **NEW** | `amap_flutter_map` 3.0.0 已集成（来自 master） |
| **SMS 发送** | 紧急短信通知 | **0%** | 完全模拟，无真实集成 |

### 3.5 原生平台

#### Android

| 功能 | 完成度 | 说明 |
|------|--------|------|
| 拨打电话 (CALL_PHONE) | **100%** | `com.nestway/phone` MethodChannel 完整实现 |
| 打开拨号盘 (ACTION_DIAL) | **100%** | 无需权限 |
| 获取位置 | **70%** | geolocator + permission_handler 插件已集成。**缺：** 原生 `com.nestway/location` MethodChannel 未实现 |
| AndroidManifest 权限 | **80%** | 已声明 ACCESS_FINE_LOCATION、ACCESS_COARSE_LOCATION、ACCESS_BACKGROUND_LOCATION、FOREGROUND_SERVICE、INTERNET。**缺：** CALL_PHONE 权限 |
| Release 签名 | **0%** | 使用 debug 签名占位 |
| Gradle 配置 | **NEW** | AGP 8.3.0 + Kotlin 1.9.10，gradle-8.7-all |

#### iOS / macOS / Windows

| 平台 | 完成度 | 说明 |
|------|--------|------|
| iOS | 80% | Info.plist 已更新定位权限描述 |
| macOS | 80% | 6 个插件已注册（app_links, geolocator, shared_preferences, sign_in_with_apple, url_launcher, video_player） |
| Windows | 80% | 4 个插件已注册（app_links, geolocator, permission_handler, url_launcher） |

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
2. **位置获取部分可用** — geolocator 插件已集成，但原生 MethodChannel `com.nestway/location` 缺失
3. **SMS 发送为假实现** — 核心安全功能的核心环节是 `Future.delayed(800ms)`

### 5.2 功能缺口

4. **`SafetyPage` 为空白占位** — `/safety` 路由指向一个只有 "安全页面" 文字的页面
5. **`DestinationSafetyPage` 路由未注册** — 已可通过首页搜索跳转，但未在 `app_routes.dart` 中注册命名路由
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

| 模块 | 完成度 | 变化 | 状态 |
|------|--------|------|------|
| 紧急联系人 CRUD | 95% | — | 基本完成 |
| SOS 历史记录 | 95% | — | 基本完成 |
| SOS 紧急报警（拨打 110） | 90% | — | 基本完成 |
| 手机验证码登录 | 85% | — | 已实现，未接入启动流程 |
| 首页（品牌+功能入口） | 90% | ↑ | 合并后含栖途品牌、功能卡片、目的地搜索 |
| SOS 短信发送 | 60% | — | 发送为模拟 |
| 虚拟护送 — 设置 | 65% | — | UI 完整，数据来源待对接 |
| 虚拟护送 — 进行中 | 75% | ↑ | 已接入定位服务 30s 轮询 |
| 虚拟护送 — 完成/超时 | 55% | — | 按钮操作为空 |
| AI 城市安全分析 | 90% | — | 首页可跳转，路由未注册 |
| 安全页面 | 5% | — | 占位符 |
| 个人资料 | 80% | ↑ | 双数据源（Provider+mock） |
| 数据库 | 75% | — | escort_tasks 表未对接，RLS 未启用 |
| 原生平台（Android） | 55% | ↑ | 定位权限已声明，gradle 配置完成 |
| **项目整体** | **~70%** | ↑5% | 三路分支合并，功能集齐，首页体验完整 |

---

## 七、本次合并新增内容

### 来自 master 分支
- 高德地图 Flutter 插件 (`amap_flutter_map` 3.0.0)
- 定位服务 (`location_service.dart`) + 30s 轮询
- 权限管理 (`permission_handler` + `geolocator`)
- Android 定位权限声明（FINE/COARSE/BACKGROUND/INTERNET）
- Android Gradle 配置恢复（AGP 8.3.0 + gradle-8.7-all）
- iOS Info.plist 定位权限描述
- macOS/Windows 插件注册更新
- codemagic.yaml CI 配置
- 护送进度页定位集成

### 来自 feature/safety-profile 分支
- 栖途品牌区（爱心+标语）
- 三大功能卡片（SOS/护送/预警，SOS和护送可点击跳转）
- 目的地搜索 + 热门目的地标签
- 目的地安全分析页接入（DeepSeek AI）
- 个人资料页本地联系人功能 + 底部导航

---

## 八、建议开发优先级

1. **认证守卫** — 将 LoginPage 设为初始路由，用 Supabase `onAuthStateChange` 控制导航
2. **修复 DestinationSafetyPage 路由** — 注册到 `app_routes.dart`
3. **完善 escort_tasks 后端对接** — 实现护送开始/打卡/超时的数据库读写
4. **真实 SMS 集成** — 接入 Twilio 或阿里云短信服务
5. **启用 RLS** — 切换为严格用户隔离策略
6. **`.env` 加入 `.gitignore`** — 防止凭据泄露
7. **ProfilePage 对接 Supabase users 表** — 替换 mock 数据
8. **清理死代码** — 移除未使用的 mock 文件和 widget
