# 虚拟护送位置服务 MVP 测试指南

## 一、修改概述

本次MVP版本为虚拟护送模块添加了完整的位置获取和上报功能，包括：

### 1.1 新增文件

| 文件 | 说明 |
|------|------|
| `lib/services/location_service.dart` | 位置服务核心类 |
| `test/location_service_test.dart` | 单元测试文件 |

### 1.2 修改文件

| 文件 | 主要改动 |
|------|---------|
| `lib/pages/escort/escort_page.dart` | 开始护送时获取起点位置 |
| `lib/pages/escort/progress_page.dart` | 定时（每30秒）获取并上报位置 |
| `lib/pages/common/timeout_page.dart` | 超时时获取最后位置 |
| `lib/pages/common/success_page.dart` | 安全到达时验证位置 |

---

## 二、功能流程图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        虚拟护送位置追踪流程                           │
└─────────────────────────────────────────────────────────────────────┘

[首页] → 点击虚拟护送按钮
              ↓
[护送设置页] → 自动获取当前位置作为起点
           → 用户设置目的地和预计时间
           → 点击"开始护送"
              ↓
[护送进行中] → 每30秒获取当前位置
           → 上报到服务器
           → 实时显示位置和上报次数
           → 倒计时结束自动跳转
              ↓
         ┌─── 超时 ───┐       ┌─── 手动打卡 ───┐
         ↓            ↓              ↓
    [超时确认页]  [安全到达页]
         ↓            ↓
    获取最后位置   获取当前位置
         ↓            ↓
    上报超时告警   上报结束记录
```

---

## 三、测试场景

### 3.1 单元测试（无需真机）

运行位置服务单元测试：

```bash
cd d:\桌面\solotrip
flutter test test/location_service_test.dart
```

**预期结果**：
- ✅ LocationPoint 序列化正确
- ✅ 单例模式正常工作
- ✅ 状态管理正常
- ✅ 所有上报方法返回 true

### 3.2 集成测试（需要模拟器/真机）

#### 测试场景一：护送设置页位置获取

**测试步骤**：
1. 打开应用，进入首页
2. 点击黄色圆形"虚拟护送"按钮
3. 观察"出发地"卡片

**预期结果**：
- 显示加载指示器（如果正在获取）
- 显示"正在获取位置..."
- 获取成功后显示地址或"我的当前位置"
- 刷新按钮可手动重新获取

#### 测试场景二：开始护送

**测试步骤**：
1. 在护送设置页，设置目的地（如"公司"）
2. 调整预计时间滑块
3. 点击"开始护送"按钮

**预期结果**：
- 跳转到护送进行中页面
- Console输出：
  ```
  🚗 护送开始: escortId=xxx, destination=公司, estimatedMinutes=15
     起点: lat=xx.xxxx, lng=xx.xxxx
  ```

#### 测试场景三：位置定时上报

**测试步骤**：
1. 在护送进行中页面观察
2. 等待30秒

**预期结果**：
- 页面显示"已上报 N 次"
- Console输出：
  ```
  📍 上报位置到服务器: escortId=xxx, lat=xx.xxxx, lng=xx.xxxx
  ```

#### 测试场景四：超时页面

**测试步骤**：
1. 等待倒计时结束（15分钟）
2. 或手动修改代码快速测试

**预期结果**：
- 自动跳转到超时确认页
- 显示最后已知位置
- Console输出：
  ```
  ⚠️ 超时告警: escortId=xxx
     最后位置: lat=xx.xxxx, lng=xx.xxxx
     紧急联系人: 妈妈, 爸爸
  ```

#### 测试场景五：安全到达

**测试步骤**：
1. 在护送进行中页面
2. 点击"安全打卡"按钮

**预期结果**：
- 跳转到成功页面
- Console输出：
  ```
  🏁 护送结束: escortId=xxx, endType=safe_arrival
     终点: lat=xx.xxxx, lng=xx.xxxx
     轨迹点数量: N
  ```

---

## 四、快速测试方法

### 4.1 修改倒计时快速测试

如果需要快速测试完整流程，可以修改 `progress_page.dart` 中的初始倒计时时间：

```dart
// 原始配置（15分钟）
// int _remainingMinutes = 14;
// int _remainingSeconds = 52;

// 测试配置（2分钟，可快速看到超时效果）
int _remainingMinutes = 1;
int _remainingSeconds = 50;
```

### 4.2 模拟位置数据

由于 MVP 版本使用 Platform Channel 获取位置，在没有原生代码实现的情况下会返回 null。可以添加模拟数据：

编辑 `lib/services/location_service.dart`：

```dart
Future<LocationPoint?> getCurrentLocation() async {
  // 临时模拟数据用于测试
  await Future.delayed(const Duration(milliseconds: 500));
  return LocationPoint(
    latitude: 31.2304,
    longitude: 121.4737,
    timestamp: DateTime.now(),
    address: '上海市黄浦区人民广场',
  );

  // 原有代码（需要原生实现）
  // try {
  //   const MethodChannel channel = MethodChannel('com.nestway/location');
  //   final result = await channel.invokeMethod('getCurrentLocation');
  //   ...
  // }
}
```

---

## 五、查看 Console 输出

### 5.1 Android Studio / VS Code

在运行应用时，Console 会显示所有位置相关的日志：

| 操作 | Console 输出 |
|------|-------------|
| 开始护送 | 🚗 护送开始: escortId=xxx, destination=xxx, estimatedMinutes=xxx |
| 位置上报 | 📍 上报位置到服务器: escortId=xxx, lat=xxx, lng=xxx |
| 超时告警 | ⚠️ 超时告警: escortId=xxx, 最后位置: lat=xxx, lng=xxx |
| 安全到达 | 🏁 护送结束: escortId=xxx, endType=safe_arrival |

### 5.2 过滤日志

在 Console 中搜索关键词：
- `护送开始`
- `上报位置`
- `超时告警`
- `护送结束`

---

## 六、后续扩展

### 6.1 连接真实后端

目前所有上报方法都是模拟实现，后续需要：

1. 替换 `reportLocationToServer` 中的模拟代码
2. 调用真实的后端 API
3. 添加错误处理和重试机制

### 6.2 原生定位实现

需要为 iOS/Android 原生代码实现 `MethodChannel`：

**Android (Kotlin/Java)**:
```kotlin
// MainActivity.kt
private val locationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.nestway/location")

locationChannel.setMethodCallHandler { call, result ->
    if (call.method == "getCurrentLocation") {
        // 调用 Android 定位 API
    }
}
```

**iOS (Swift/Objective-C)**:
```swift
// AppDelegate.swift
let controller = window?.rootViewController as! FlutterViewController
let locationChannel = FlutterMethodChannel(name: "com.nestway/location", binaryMessenger: controller.binaryMessenger)

locationChannel.setMethodCallHandler { call, result in
    if call.method == "getCurrentLocation" {
        // 调用 iOS CoreLocation
    }
}
```

---

## 七、已知限制

| 限制 | 说明 | 解决方案 |
|------|------|---------|
| 无原生实现 | Platform Channel 返回 null | 添加模拟数据测试 UI |
| 无后端连接 | 所有上报是模拟的 | 连接真实后端 API |
| 无地图展示 | 只有文字位置 | 集成高德/百度地图 SDK |
| 无后台定位 | 应用切后台会停止 | 使用后台定位服务 |

---

## 八、测试检查清单

测试完成后，确认以下功能正常：

- [ ] 护送设置页自动获取位置
- [ ] 刷新按钮可重新获取位置
- [ ] 位置获取中显示加载状态
- [ ] 开始护送按钮在获取位置前禁用
- [ ] 开始护送时输出日志
- [ ] 护送进行中每30秒上报位置
- [ ] 显示上报次数
- [ ] 超时页面显示最后位置
- [ ] 安全到达页面验证位置
- [ ] 护送结束后重置状态
