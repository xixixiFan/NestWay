# NestWay（栖途）功能完成度分析报告

**日期：** 2026-05-17（SOS 定位链路修复更新）
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
| **LoginPage** | `/login` | 85% | 手机号+验证码登录，Supabase Auth 对接完成。**已设为初始路由**（`app.dart:21`），每次启动自动跳转登录页。**缺：** 无持久化 Auth 状态 — App 重启后需重新登录；Supabase 后台 Phone Auth 需配置 Twilio 才能真实发送验证码；支持演示模式绕过验证码 |
| **SosPage** | `/sos` | 95% | 三大风险卡片（报警/位置共享/安全视频），长按 SOS 触发拨号 110（Android `ACTION_CALL`），视频播放弹窗。`triggerSos()` 完整链路已贯通：定位→上报 Supabase→拨号→分享位置 URL。**缺：** SMS 发送为模拟（`Future.delayed`）；未使用独立 `SosButton` widget（逻辑内联在页面中） |
| **SendSosMessagePage** | `/send_sos_message` | 60% | UI 完整（收件人选择+消息编辑）。**缺：** 发送动作为 `Future.delayed` 模拟，无真实 SMS API；位置和昵称硬编码 |
| **EmergencyContactsPage** | `/emergency_contacts` | 95% | 完整 CRUD，Supabase 对接。增删改查全部可用 |
| **SosHistoryPage** | `/sos_history` | 95% | 从 Supabase `sos_logs` 表拉取历史，下拉刷新，类型图标区分 |

### 2.2 虚拟护送模块

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **EscortPage** | `/escort` | 70% | 出发地/目的地/ETA 设置，GPS 获取当前位置（`location_service.dart`）。**缺：** 联系人使用 mock 数据（`mock_contacts`）而非真实 Provider；出发地刷新按钮无操作 |
| **ProgressPage** | `/escort_progress` | 80% | 倒计时器（真实 `Timer` 实现）、路线展示、安全打卡按钮。已接入 `EscortLocationService`（30s 轮询定位+高德逆地理编码）。**缺：** 出发地/目的地硬编码；联系人拨打按钮无操作；护送状态无后端持久化（仅 `print()` 日志） |
| **SuccessPage** | `/success` | 70% | 护送完成确认页，含到达验证（`_verifyArrival`）、位置检查。**缺：** 通知发送为假逻辑；无 escort_tasks 表写入 |
| **TimeoutPage** | `/timeout` | 70% | 超时警告页，含最后位置获取（`_fetchLastLocation`）、"我很安全"/"需要帮助"按钮。**缺：** 自动通知未实现；无 escort_tasks 表写入 |

### 2.3 安全与资料

| 页面 | 路由 | 完成度 | 说明 |
|------|------|--------|------|
| **SafetyPage** | `/safety` | **5%** | 仅 11 行代码 — `Center(child: Text('安全页面'))`，完全是占位符 |
| **DestinationSafetyPage** | 未注册路由 | **90%** | DeepSeek AI 城市安全分析完整实现（499 行）。首页搜索框和热门目的地可直接跳转（通过 `MaterialPageRoute` 而非命名路由）。**缺：** 未注册到 `app_routes.dart` 路由表；DeepSeek API Key 硬编码在源码中 |
| **ProfilePage** | `/profile` | 85% | 用户信息卡片+守护统计+紧急联系人列表（Provider+本地双数据源）。退出登录按钮已实现（`profile_page.dart:169`）— 清除内存状态并跳转到登录页。**缺：** 用户数据来自 mock 而非 Supabase `users` 表；退出登录未调用 `Supabase.auth.signOut()` |

---

## 三、后端与数据层完成度

### 3.1 数据库（Supabase PostgreSQL）

| 表名 | 记录数 | 完成度 | 说明 |
|------|--------|--------|------|
| `users` | 1 | 90% | 用户表结构完整。**缺：** 无 avatar 上传；注册后手机号唯一约束正常 |
| `emergency_contacts` | 3 | 95% | 完整 CRUD，sort_order 自增。**缺：** user_id 在代码中硬编码为 1 |
| `sos_logs` | 3 | 90% | SOS 事件记录完整。**缺：** 插入时 user_id 硬编码为 1 |
| `escort_tasks` | **0** | **20%** | 表结构在 `sql/supabase_init.sql` 中完整定义（含 status/位置/时间等字段），RLS 策略已编写。**但 Dart 代码中零引用** — 无 CRUD Service、无 UI 对接、无数据写入。`EscortLocationService` 的所有"上报"方法均为 `print()` + `Future.delayed` 模拟 |

### 3.2 RLS 安全策略

**当前状态：开发模式 — RLS 策略已编写但过于宽松**

`sql/full_rls_config.sql` 中的策略允许所有用户读写所有表（`USING (true)` / `WITH CHECK (true)`），未按 `auth.uid()` 做用户隔离。生产环境需切换到严格的用户隔离策略（SQL 已存在于 `supabase_init.sql` 中但未启用）。

### 3.3 Service 层

| Service | 方法数 | 完成度 | 说明 |
|---------|--------|--------|------|
| **SupabaseService** | 2 | 90% | 单例初始化。**缺：** URL/Key 硬编码在源码中（非 .env 读取）；`.env` 和 `.env.example` 中亦有相同 Key，Key 散落三处 |
| **SosService** | 13 | 95% | 核心服务（13 个方法），SOS 完整链路贯通。`getCurrentLocation()` → `geolocator` 权限检查 → `com.nestway/location` MethodChannel（`MainActivity.kt` 已实现）→ 经纬度 → `reportSosEvent()` 写入 Supabase + `makePhoneCall()` 拨号 + `shareLocation()` 生成高德链接 |
| **AuthProvider** | 3 | 80% | ChangeNotifier，含 `loginAsDemoUser` / `logout`。**缺：** 状态仅存内存，App 重启丢失；logout 未调用 `Supabase.auth.signOut()` |
| **ContactsProvider** | 5 | 95% | ChangeNotifier 状态管理完整，CRUD 全部对接 Supabase |
| **EscortLocationService** | - | 70% | 新增（272 行），支持 30s 轮询定位+高德逆地理编码。**缺：** 高德 API Key 硬编码（`location_service.dart:86`）；`report*` 方法均为 `print()` 模拟 |

### 3.4 外部 API 集成

| API | 用途 | 完成度 | 说明 |
|-----|------|--------|------|
| **Supabase REST/DB** | 数据存储+查询 | **100%** | 读写正常 |
| **Supabase Auth (Phone OTP)** | 手机验证码登录 | **90%** | 代码完整，需 Supabase 后台开启 Phone Auth + Twilio 配置 |
| **DeepSeek AI** | 城市安全分析 | **90%** | API 调用完整，JSON 解析正常。**缺：** API Key `sk-1f17d93786ac413187006742996cac29` 硬编码在 `destination_safety_page.dart:45`，非 `--dart-define` 传入 |
| **高德地图 URL** | 位置分享 URL | **100%** | URL 生成逻辑完整，无需 API Key |
| **高德逆地理编码** | 坐标转地址 | **80%** | 已集成在 `EscortLocationService` 中。**缺：** API Key 硬编码（`location_service.dart:86`）；失败时使用 mock 中文地址兜底 |
| **高德 Flutter 地图** | 地图显示 | **NEW** | `amap_flutter_map` 3.0.0 已集成（来自 master） |
| **SMS 发送** | 紧急短信通知 | **0%** | 完全模拟（`Future.delayed(800ms)` + 弹窗），无 Twilio/阿里云短信等真实集成 |

### 3.5 原生平台

#### Android

| 功能 | 完成度 | 说明 |
|------|--------|------|
| 拨打电话 (ACTION_CALL) | **90%** | `com.nestway/phone` MethodChannel 在 `MainActivity.kt:14-38` 完整实现。**缺：** `CALL_PHONE` 权限未在 AndroidManifest 中声明；包名不匹配（Manifest 为 `com.example.solotrip`，Channel 名为 `com.nestway`） |
| 打开拨号盘 (ACTION_DIAL) | **100%** | 无需权限，`MainActivity.kt` 已实现 `openDialer` |
| 获取位置 | **100%** | `com.nestway/location` MethodChannel 已在 `MainActivity.kt` 完整实现，通过 `LocationManager` 获取 GPS+网络定位；Dart 侧通过 `geolocator` 做权限前置检查，双通道协同工作 |
| AndroidManifest 权限 | **80%** | 已声明 ACCESS_FINE_LOCATION、ACCESS_COARSE_LOCATION、ACCESS_BACKGROUND_LOCATION、FOREGROUND_SERVICE、INTERNET。**缺：** CALL_PHONE 权限；无 SEND_SMS 权限 |
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

以下 mock 数据文件已定义但未被任何页面导入使用：
- `mock_city_safety.dart`（7 个城市安全数据）— 未被 import
- `mock_videos.dart`（2 个视频条目）— 未被 import
- `mock_sos_logs.dart`（3 条 SOS 历史）— 未被 import，SosHistoryPage 已改用 Supabase 真实数据
- `mock_user.dart`（1 个用户 范颖）— 未被 import，ProfilePage 使用内联 mock 数据

以下文件被实际引用（非死代码）：
- `mock_contacts.dart`（3 个联系人）— 被 escort_page、progress_page、timeout_page 引用
- `demo_users.dart`（3 个演示用户）— 被 login_page 引用

---

## 五、关键缺失与风险

### 5.1 阻塞性问题

1. **无认证守卫/无持久化登录** — LoginPage 已设为初始路由，但 AuthProvider 状态仅存内存，App 重启后需重新登录；所有 DB 操作使用 `user_id=1`；登出未调用 `Supabase.auth.signOut()`
2. **SMS 发送为假实现** — 核心安全功能的关键环节是 `Future.delayed(800ms)` + 弹窗，无任何真实 SMS 网关集成

### 5.2 功能缺口

4. **`SafetyPage` 为空白占位** — `/safety` 路由指向仅 11 行代码的占位页面
5. **`DestinationSafetyPage` 路由未注册** — 只能通过首页 `MaterialPageRoute` 跳转，未在 `app_routes.dart` 中注册命名路由
6. **`escort_tasks` 表完全未对接** — 表结构在 SQL 中完整定义，但 Dart 代码中零引用；护送开始/打卡/超时全为 `print()` 模拟
7. **ProfilePage 用户数据来自 mock** — 不从 Supabase `users` 表读取
8. **护送流程多处硬编码** — 联系人使用 `mock_contacts`（非 Provider）、出发地/目的地/昵称/倒计时为静态值
9. **App 重启丢失登录状态** — AuthProvider 仅内存级，无 token/session 持久化

### 5.3 安全隐患

10. **Supabase URL + Anon Key 散落三处** — `supabase_service.dart`（硬编码）、`.env`、`.env.example`（Anon Key 为真实值）中均有明文
11. **RLS 策略过于宽松** — `full_rls_config.sql` 使用 `USING (true)` 全放行，任何客户端可读写任意用户数据
12. **DeepSeek API Key 硬编码在源码** — `destination_safety_page.dart:45` 明文存储 `sk-1f17d93786ac413187006742996cac29`
13. **高德 API Key 硬编码在源码** — `location_service.dart:86` 明文存储 `89ff90f769765ecd5f68e2cb48e283cb`
14. **`.env` 已加入 `.gitignore`** ✅ — 但 `.env.example` 中的 Anon Key 为真实值（非占位符），`.env` 中的 Service Role Key 不应出现在客户端项目

---

## 六、完成度总览

| 模块 | 完成度 | 变化 | 状态 |
|------|--------|------|------|
| 紧急联系人 CRUD | 95% | — | 基本完成 |
| SOS 历史记录 | 95% | — | 基本完成 |
| SOS 紧急报警（拨打 110） | 90% | — | 基本完成（长按拨号已实现） |
| 手机验证码登录 | 85% | ↑ | 已设为初始路由；缺持久化+真实验证码发送 |
| 首页（品牌+功能入口） | 90% | — | 栖途品牌、功能卡片、目的地搜索 |
| SOS 紧急定位上报 | 95% | ↑ | 定位→上报→拨号→分享链路贯通，MethodChannel+geolocator 双通道协同 |
| SOS 短信发送 | 60% | — | 发送为模拟，无真实 SMS 网关 |
| 虚拟护送 — 设置 | 70% | ↑ | UI 完整，GPS 获取已实现；联系人仍用 mock |
| 虚拟护送 — 进行中 | 80% | ↑ | 真实 Timer+定位轮询+逆地理编码；缺后端写入 |
| 虚拟护送 — 完成/超时 | 70% | ↑ | 到达验证/最后位置获取已实现；缺后端写入 |
| AI 城市安全分析 | 90% | — | 功能完整；Key 硬编码+路由未注册 |
| 安全页面 | 5% | — | 占位符（11 行） |
| 个人资料 | 85% | ↑ | 退出登录已实现；用户数据仍为 mock |
| 数据库 | 70% | ↓ | escort_tasks 零引用；RLS 过于宽松 |
| 原生平台（Android） | 80% | ↑ | 电话+定位双 MethodChannel 完成；CALL_PHONE 权限缺失 |
| **项目整体** | **~75%** | ↑3% | SOS 定位链路修复（MethodChannel 实现+geolocator 权限协同）；API Key 硬编码和 escort_tasks 零对接仍拉低后端分数 |

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

1. **API Key 安全治理（最高优先级）** — 将 DeepSeek Key（`destination_safety_page.dart:45`）、高德 Key（`location_service.dart:86`）、Supabase Key（`supabase_service.dart`）统一迁移到 `.env` + `--dart-define`，清理 `.env.example` 中的真实 Key
2. **认证持久化** — 用 Supabase `onAuthStateChange` + `SharedPreferences` 持久化登录状态，避免 App 重启后重新登录；登出时调用 `Supabase.auth.signOut()`
3. ~~**实现 `com.nestway/location` MethodChannel**~~ ✅ 已完成 — 在 `MainActivity.kt` 中添加定位 Channel 处理，`SosService.getCurrentLocation()` 集成 `geolocator` 权限检查
4. **修复 DestinationSafetyPage 路由** — 注册到 `app_routes.dart`
5. **完善 escort_tasks 后端对接** — 实现护送开始/打卡/超时的数据库读写，替换 `EscortLocationService` 中的 `print()` 模拟
6. **真实 SMS 集成** — 接入 Twilio 或阿里云短信服务，替换 `SendSosMessagePage` 和 SosPage 中的模拟发送
7. **启用严格 RLS** — 从 `USING (true)` 切换为基于 `auth.uid()` 的用户隔离策略
8. **ProfilePage 对接 Supabase users 表** — 替换 mock 数据
9. **AndroidManifest 补全权限** — 添加 `CALL_PHONE`、`SEND_SMS` 权限
10. **清理死代码** — 移除 4 个未使用的 mock 文件 + 4 个未使用的 widget 文件（约 800 行死代码）
