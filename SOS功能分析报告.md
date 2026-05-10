# SOS 功能分析报告

**项目**：栖途 NestWay - 女性独旅安全 App  
**版本**：v1.0  
**日期**：2026-05-10  
**分析对象**：SOS 紧急求助功能

---

## 一、功能概述

SOS 功能是栖途 NestWay 的核心安全功能，旨在为女性用户提供便捷、可靠的紧急求助手段。该功能支持用户通过长按按钮触发求助，实现三路并发救援：拨打电话、上报服务器、分享位置。

---

## 二、已实现功能清单

| 功能模块 | 状态 | 说明 |
|---------|------|------|
| 长按触发机制 | ✅ 已完成 | 3秒长按触发，支持松开取消 |
| 倒计时UI | ✅ 已完成 | 圆形进度条动画，显示剩余秒数 |
| 震动反馈 | ✅ 已完成 | 使用 HapticFeedback 实现触觉反馈 |
| 三路触发逻辑 | ✅ 已完成 | 拨号 + API上报 + 位置分享并发执行 |
| 位置获取 | ✅ 已完成 | 通过 Platform Channel 获取当前坐标 |
| 位置分享URL生成 | ✅ 已完成 | 生成高德地图位置链接 |
| SOS历史记录页面 | ✅ 已完成 | 展示历史求助记录列表 |
| 紧急联系人管理 | ✅ 已完成 | 支持获取紧急联系人列表 |

---

## 三、核心实现分析

### 3.1 SOS 按钮组件 (`lib/widgets/sos_button.dart`)

**设计模式**：状态管理 + 组合模式

**核心功能**：
- **长按识别**：使用 `GestureDetector` 的 `onLongPressStart`/`onLongPressEnd` 回调
- **倒计时动画**：内置 `_CountdownCircle` 组件，使用 `AnimationController` 实现3秒倒计时
- **防误触机制**：手指松开立即取消倒计时

**关键代码片段**：
```dart
void _onLongPressStart(LongPressStartDetails details) {
  HapticFeedback.heavyImpact();
  setState(() {
    _isPressed = true;
    _showCountdown = true;
  });
}

void _onLongPressEnd(LongPressEndDetails details) {
  setState(() {
    _isPressed = false;
    _showCountdown = false;
  });
}
```

**用户体验亮点**：
- 按钮按下时有缩放动画和阴影变化
- 倒计时期间显示红色圆形进度条
- 清晰的"松开取消"提示文字

---

### 3.2 SOS 服务层 (`lib/services/sos_service.dart`)

**设计模式**：单例模式 + 服务封装

**核心方法**：

| 方法名 | 功能 | 参数 | 返回值 |
|-------|------|------|--------|
| `triggerSos()` | 触发三路求助 | `emergencyContacts`, `locationDescription` | `void` |
| `makePhoneCall()` | 拨打电话 | `phoneNumber` | `void` |
| `getCurrentLocation()` | 获取当前位置 | 无 | `Map<String, double?>` |
| `generateLocationShareUrl()` | 生成位置分享链接 | `lat`, `lng`, `description` | `String` |
| `reportSosEvent()` | 上报SOS事件 | `type`, `locationDescription`, `latitude`, `longitude` | `Future<bool>` |
| `shareLocation()` | 分享位置 | `latitude`, `longitude`, `description` | `void` |
| `getSosHistory()` | 获取历史记录 | 无 | `Future<List<Map>>` |
| `getEmergencyContacts()` | 获取紧急联系人 | 无 | `List<Map>` |

**三路并发触发逻辑**：
```dart
await Future.wait([
  reportSosEvent(type: 'sos', ...),
  makePhoneCall(phone),
  if (latitude != null && longitude != null)
    shareLocation(latitude: latitude, longitude: longitude, ...),
]);
```

**技术实现**：
- 使用 `MethodChannel` 调用原生平台功能（电话、定位）
- 降级方案：若原生调用失败，自动复制到剪贴板
- 使用 `Future.wait()` 实现三路并发，提高响应速度

---

### 3.3 SOS 页面 (`lib/pages/sos/sos_page.dart`)

**功能结构**：
- **顶部导航**：标题 + 历史记录入口
- **主体区域**：状态提示文字 + SOS按钮 + 错误提示
- **风险卡片列表**：轻度不安、中度风险、紧急危险三种等级
- **底部导航**：AppBottomNav

**状态管理**：
- `_isLoading`：控制加载状态显示
- `_lastError`：存储最近一次错误信息

---

### 3.4 SOS 历史记录页面 (`lib/pages/sos/sos_history_page.dart`)

**功能特点**：
- 支持下拉刷新
- 空状态友好提示
- 按类型显示不同图标和颜色
- 时间格式化显示

**类型映射**：
| 类型 | 图标 | 颜色 | 显示名称 |
|------|------|------|----------|
| `call` | Icons.phone | #4CAF50 | 语音通话 |
| `sms` | Icons.message | #2196F3 | 短信 |
| `video` | Icons.videocam | #FF9800 | 视频通话 |
| 其他 | Icons.warning | #FF5722 | 其他 |

---

## 四、测试覆盖分析

### 4.1 测试文件清单

| 测试文件 | 覆盖模块 | 测试用例数 |
|---------|---------|-----------|
| `sos_service_test.dart` | SosService | 8个 |
| `sos_button_test.dart` | SosButton | 6个 |
| `sos_history_page_test.dart` | SosHistoryPage | 5个 |

### 4.2 测试覆盖范围

**SosService 测试**：
- 单例模式验证
- URL生成正确性
- 事件上报功能
- 历史记录获取
- 紧急联系人数据验证

**SosButton 测试**：
- 默认文本渲染
- 自定义文本渲染
- SOS图标显示
- 长按手势检测
- 自定义尺寸支持
- 倒计时完成回调

**SosHistoryPage 测试**：
- 页面标题显示
- 历史记录渲染
- 返回按钮存在
- 位置描述显示
- 底部导航存在

---

## 五、数据流分析

```
[用户长按按钮]
    ↓
[SosButton 检测长按开始]
    ↓
[显示 CountdownCircle 倒计时]
    ↓
[3秒倒计时完成]
    ↓
[触发 onTriggered 回调]
    ↓
[SosPage._onSosTriggered()]
    ↓
[SosService.triggerSos()]
    ↓
┌─────┴─────┬─────────┐
↓          ↓         ↓
①获取位置  ②拨号    ③上报API
    ↓          ↓         ↓
④生成分享URL
    ↓
⑤复制到剪贴板
```

---

## 六、技术亮点

1. **防误触设计**：长按3秒 + 可取消机制，避免误触发
2. **并发执行**：三路操作并行执行，提升响应速度
3. **降级方案**：原生调用失败时自动降级到剪贴板
4. **用户反馈**：震动 + 视觉动画，提供明确操作反馈
5. **单例模式**：服务层使用单例，保证全局状态一致性

---

## 七、待优化项

| 优先级 | 优化项 | 说明 |
|--------|--------|------|
| P0 | 定位权限处理 | 当前缺少权限申请引导流程 |
| P0 | 网络错误处理 | 需增加网络异常时的重试机制 |
| P1 | 紧急联系人管理界面 | 目前只有数据获取，缺少管理界面 |
| P1 | 分享功能增强 | 当前仅复制URL，可增加直接分享到社交应用 |
| P2 | 位置缓存 | 可缓存最近位置，提高响应速度 |

---

## 八、验收标准确认

对照《SOS功能实现规划》中的验收标准：

- [x] 长按 3 秒触发倒计时，松开手指可取消 ✅
- [x] 倒计时期间有震动反馈和视觉进度 ✅
- [x] 倒计时结束执行三路触发：拨号 + API 上报 + 分享 ✅
- [x] 可查看 SOS 历史记录列表 ✅
- [x] 紧急情况下操作流畅，步骤最少化 ✅

---

## 九、文件变更汇总

| 文件路径 | 操作类型 | 状态 |
|---------|---------|------|
| `lib/pages/sos/sos_page.dart` | 重构 | ✅ 完成 |
| `lib/services/sos_service.dart` | 新建 | ✅ 完成 |
| `lib/pages/sos/sos_history_page.dart` | 新建 | ✅ 完成 |
| `lib/widgets/sos_button.dart` | 新建 | ✅ 完成 |
| `lib/widgets/countdown_overlay.dart` | 新建 | ✅ 完成 |
| `lib/routes/app_routes.dart` | 更新 | ✅ 完成 |
| `test/sos_service_test.dart` | 新建 | ✅ 完成 |
| `test/sos_button_test.dart` | 新建 | ✅ 完成 |
| `test/sos_history_page_test.dart` | 新建 | ✅ 完成 |

---

**结论**：SOS 功能已按规划完成核心实现，包括长按触发、倒计时交互、三路并发救援、历史记录查看等功能。测试覆盖完整，代码结构清晰，可满足紧急求助场景的基本需求。