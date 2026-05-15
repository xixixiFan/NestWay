# SOS 功能实现规划

**项目**：栖途 NestWay - 女性独旅安全小程序
**负责人**：只负责 SOS 功能和界面实现
**技术栈**：Flutter / UniApp（Flutter 框架）
**文档版本**：v2.0

***

## 一、需求理解

### 1.1 SOS 核心功能（技术方案 v2.0 第 6.2 节）

**触发逻辑（前端）**：

* 用户长按 SOS 按钮 **3 秒**（防误触）

* 震动反馈 + **可取消倒计时 UI**

* 确认后**三路并发执行**：

  1. **拨号**：调用 `wx.makePhoneCall()` 调起拨号界面（需用户点击确认）
  2. **上报**：调用 SOS API 上报事件 + 当前坐标，后端异步推送通知给紧急联系人
  3. **分享**：通过 `wx.shareFileMessage` 将位置链接发送给联系人

**SOS 事件历史**：用户可查看历史求助记录

### 1.2 风险等级卡片（现有 UI）

| 风险等级 | 颜色           | 触发动作                    |
| ---- | ------------ | ----------------------- |
| 轻度不安 | `#DFF5E3` 浅蓝 | 播放模拟通话/视频，制造"有人在联系我"的氛围 |
| 中度风险 | `#FFF4D6` 浅黄 | 实时位置共享给紧急联系人            |
| 紧急危险 | `#FFE0E0` 浅红 | 尝试拨打报警电话，并发送位置信息        |

***

## 二、现有代码分析

### 2.1 项目结构

```
lib/
├── app/app.dart                    # App 入口，路由配置
├── routes/app_routes.dart          # 路由定义
├── pages/sos/sos_page.dart         # SOS 页面（当前为静态 UI）
├── services/sos_service.dart       # SOS 服务（空文件）
├── mock/mock_sos_logs.dart          # SOS 日志 Mock 数据
├── mock/mock_contacts.dart          # 紧急联系人 Mock 数据
├── widgets/
│   ├── primary_button.dart          # 黄色大按钮组件
│   ├── risk_card.dart              # 风险等级卡片组件
│   └── app_bottom_nav.dart         # 底部导航组件
```

### 2.2 当前 SOS 页面状态

* 仅有静态 UI：长按提示文字 + PrimaryButton（无交互）+ 三个静态 RiskCard

* **缺少**：长按交互、倒计时 UI、震动反馈、三路触发逻辑

### 2.3 需要实现的功能清单

1. **长按交互**：GestureDetector + 长按 3 秒识别
2. **倒计时 UI**：可取消的 3 秒倒计时弹窗/覆盖层
3. **震动反馈**：HapticFeedback / Vibration API
4. **三路触发逻辑**：

   * 拨号：URL Launcher 或平台渠道调用电话

   * 上报：调用 SOS API（含位置信息）

   * 分享：分享位置链接
5. **SOS 历史记录页面**：查看历史求助记录
6. **紧急联系人管理**：可从 Profile 页面跳转管理

***

## 三、实现规划

### Phase 1：SOS 页面核心交互实现

**文件**：`lib/pages/sos/sos_page.dart`

#### 任务 1.1：长按按钮组件封装

* 将 `PrimaryButton` 改造支持**长按**和**普通点击**两种模式

* 或新建 `SosButton` 组件，专门处理 SOS 按钮逻辑

#### 任务 1.2：倒计时弹窗 UI

* 3 秒倒计时进度环/圆圈动画

* 手指松开**取消**功能

* 倒计时结束自动触发求助流程

#### 任务 1.3：震动反馈

* 使用 `flutter_vibrate` 或原生渠道实现震动

#### 任务 1.4：三路触发逻辑

```
[用户长按 3 秒]
      ↓
[显示倒计时弹窗，震动反馈]
      ↓
[倒计时结束 → 三路并发]
      ↓
┌─────┴─────┬─────────┐
↓          ↓         ↓
①拨号    ②上报API  ③分享位置
```

**注意**：微信小程序环境使用 `uni.request` / `uni.makePhoneCall`，Flutter 环境需通过 **平台渠道（Platform Channel）** 或 **url\_launcher** 实现拨号

***

### Phase 2：SOS 服务层

**文件**：`lib/services/sos_service.dart`

#### 任务 2.1：SOS API 服务封装

* `triggerSos()` - 触发 SOS，发送位置到后端

* `getSosHistory()` - 获取历史记录

* `shareLocation()` - 生成分享位置链接

#### 任务 2.2：位置服务集成

* 获取当前位置（使用 `geolocator` 或高德 SDK）

***

### Phase 3：SOS 历史记录页面

**文件**：新建 `lib/pages/sos/sos_history_page.dart`

* 展示历史 SOS 记录列表（时间、地点、类型）

* 点击可查看详情

***

### Phase 4：紧急联系人入口（可选）

* 在 Profile 页面添加「紧急联系人管理」入口

* 或在 SOS 页面内直接显示紧急联系人列表

***

## 四、文件清单

| 文件                                    | 操作        | 说明               |
| ------------------------------------- | --------- | ---------------- |
| `lib/pages/sos/sos_page.dart`         | **重构**    | 完整 SOS 交互逻辑      |
| `lib/services/sos_service.dart`       | **新建/重写** | SOS API 服务封装     |
| `lib/pages/sos/sos_history_page.dart` | **新建**    | SOS 历史记录页面       |
| `lib/widgets/sos_button.dart`         | **新建**    | SOS 专用按钮组件（含倒计时） |
| `lib/widgets/countdown_overlay.dart`  | **新建**    | 倒计时弹窗组件          |
| `lib/routes/app_routes.dart`          | **更新**    | 添加 SOS 历史路由      |

***

## 五、技术细节

### 5.1 拨号实现（Flutter）

```dart
// 使用 url_launcher
import 'package:url_launcher/url_launcher.dart';

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
}
```

### 5.2 震动反馈

```dart
// 使用 vibration 包
import 'package:vibration/vibration.dart';

Future<void> vibrate() async {
  if (await Vibration.hasVibrator()) {
    Vibration.vibrate(duration: 500);
  }
}
```

### 5.3 位置获取

```dart
import 'package:geolocator/geolocator.dart';

Future<Position> getCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  return await Geolocator.getCurrentPosition();
}
```

### 5.4 倒计时 UI 伪代码

```dart
Stack(
  children: [
    // 底层：SOS 按钮
    PrimaryButton(
      text: '长按求助',
      size: 160,
      onPressed: () {}, // 空，交互由 GestureDetector 处理
    ),
    // 顶层：倒计时遮罩（count > 0 时显示）
    if (countdown > 0)
      Positioned.fill(
        child: CountdownOverlay(
          seconds: countdown,
          onCancel: () => cancel(),
        ),
      ),
  ],
)
```

***

## 六、里程碑

| 阶段       | 交付物                       | 优先级 |
| -------- | ------------------------- | --- |
| Sprint 1 | SOS 页面核心交互（长按 + 倒计时 + 震动） | P0  |
| Sprint 2 | 三路触发逻辑（拨号 + API 上报 + 分享）  | P0  |
| Sprint 3 | SOS 历史记录页面                | P1  |
| Sprint 4 | 紧急联系人入口                   | P1  |

***

## 七、风险与注意事项

1. **微信小程序限制**：`wx.makePhoneCall()` 需用户确认，不能静默拨号
2. **定位权限**：首次使用需申请位置权限，需做好权限申请引导
3. **倒计时可取消**：用户手指松开应立即取消倒计时，避免误触
4. **并发处理**：三路触发应使用 `Future.wait()` 或独立 try-catch，任何一路失败不应影响其他路

***

## 八、验收标准

* [ ] 长按 3 秒触发倒计时，松开手指可取消

* [ ] 倒计时期间有震动反馈和视觉进度

* [ ] 倒计时结束执行三路触发：拨号 + API 上报 + 分享

* [ ] 可查看 SOS 历史记录列表

* [ ] 紧急情况下操作流畅，步骤最少化

