# 栖途 NestWay 项目 Code Wiki

## 一、项目概述

### 1.1 项目简介

栖途（NestWay）是一款专为女性独自旅行设计的全方位安全守护应用，旨在为独旅女性提供实时位置共享、一键紧急求助、目的地安全预警等核心功能，帮助用户安全、安心地完成每一次独自旅行。

### 1.2 技术栈信息

本项目基于 Flutter 跨平台框架开发，采用 Dart 语言编写，可同时编译运行于 Android、iOS、macOS、Windows、Linux 以及 Web 等多个平台。Flutter 框架凭借其高效的渲染引擎和丰富的生态系统，能够为移动应用提供流畅的用户体验和原生级别的性能表现。项目遵循语义化版本规范，当前版本为 1.0.0，采用 Dart SDK 版本 3.0.0 及以上版本进行开发。

### 1.3 核心依赖库

项目在 `pubspec.yaml` 中声明了以下核心依赖，这些依赖为应用提供了关键的功能支持。`flutter` 依赖作为 Flutter SDK 的核心，为应用提供了完整的跨平台开发框架、丰富的 Material Design 组件库以及高效的渲染引擎。`video_player` 依赖（版本 2.8.0）提供了跨平台的视频播放能力，支持本地视频和网络视频的播放，可用于安全提示视频的播放功能。`http` 依赖（版本 1.2.0）则提供了 HTTP 网络请求能力，主要用于与后端 API 服务的通信以及第三方安全预警服务的调用。

### 1.4 项目命名规范

本项目在代码中使用了统一的命名空间前缀 `com.nestway`，例如原生平台通信的 MethodChannel 标识符为 `com.nestway/phone` 和 `com.nestway/location`。应用名称为「栖途」，品牌名称为「NestWay」，在界面展示中统一使用这两种命名方式。

## 二、项目架构设计

### 2.1 整体架构概述

本项目采用分层架构设计，将应用代码清晰地划分为多个层次，每个层次承担独立的职责，从而实现代码的高内聚、低耦合，便于维护和扩展。整个项目结构如下所示：

```
lib/
├── app/                 # 应用核心配置层
├── mock/                # 测试数据层
├── pages/               # 页面展示层
├── routes/              # 路由配置层
├── services/            # 业务逻辑层
├── utils/               # 工具函数层
├── widgets/             # 可复用组件层
└── main.dart            # 应用入口
```

这种分层结构遵循了 Flutter 开发中的经典三层架构模式：展示层负责用户界面的呈现和交互，逻辑层处理业务规则和数据处理，而配置层则负责应用的整体初始化和全局设置。

### 2.2 各层职责说明

**应用核心配置层（app/）** 负责应用的全局配置，包括主题设置、路由初始化等全局性配置。在 `app.dart` 文件中定义了 `NestWayApp` 组件，这是整个应用的根组件，配置了 Material Design 主题（包括主色调为黄色 `#FFFFE066`、背景色为淡紫色 `#F3F0FF`）、应用标题以及路由表。

**测试数据层（mock/）** 提供模拟数据用于开发和测试阶段，包括用户信息模拟数据 `mock_user.dart`、紧急联系人模拟数据 `mock_contacts.dart`、SOS 日志模拟数据 `mock_sos_logs.dart`、城市安全数据模拟 `mock_city_safety.dart` 以及视频资源模拟 `mock_videos.dart`。这些模拟数据使得开发人员能够在不依赖后端服务的情况下进行前端开发和单元测试。

**页面展示层（pages/）** 包含应用的所有页面组件，按功能模块进一步细分为六个子目录。`home/` 目录存放首页 `home_page.dart`，这是用户打开应用后看到的第一个页面，提供了虚拟护送功能的入口。`sos/` 目录包含 SOS 紧急求助相关的三个页面：`sos_page.dart` 提供 SOS 主页面的三个求助选项，`sos_history_page.dart` 展示求助历史记录列表，`send_sos_message_page.dart` 提供发送求助短信的界面。`escort/` 目录包含虚拟护送功能页面：`escort_page.dart` 用于设置护送起点、终点和时间，`progress_page.dart` 展示护送进行中的状态和倒计时。`safety/` 目录存放安全相关页面：`safety_page.dart` 是通用安全页面，`destination_safety_page.dart` 提供目的地安全预警查询功能，支持 AI 分析城市安全信息。`profile/` 目录包含用户个人中心页面 `profile_page.dart`，用于管理用户信息和紧急联系人。`common/` 目录存放通用页面：`success_page.dart` 和 `timeout_page.dart` 分别用于展示操作成功和超时状态。

**路由配置层（routes/）** 集中管理应用的页面路由配置。`app_routes.dart` 文件定义了所有路由的路径常量，包括首页路由 `home`（`/`）、SOS 页面路由 `sos`（`/sos`）、SOS 历史记录路由 `sosHistory`（`/sos_history`）、发送 SOS 消息路由 `sendSosMessage`（`/send_sos_message`）、虚拟护送路由 `escort`（`/escort`）、护送进度路由 `escortProgress`（`/escort_progress`）、成功页面路由 `success`（`/success`）、超时页面路由 `timeout`（`/timeout`）、安全页面路由 `safety`（`/safety`）以及个人中心路由 `profile`（`/profile`）。同时，该文件还提供了静态的 `routes` 映射表，将每个路由路径关联到对应的页面组件构建器。

**业务逻辑层（services/）** 封装核心业务逻辑和与原生平台的通信。`sos_service.dart` 中的 `SosService` 类是核心服务类，采用单例模式实现，提供了拨打电话、获取位置、生成位置分享链接、报告 SOS 事件、分享位置、获取 SOS 历史记录、获取紧急联系人以及触发 SOS 等核心功能方法。该服务类通过 Flutter 的 MethodChannel 与原生平台进行通信，实现平台特定的功能调用。

**工具函数层（utils/）** 存放通用工具函数和常量定义，`constants.dart` 文件用于定义应用级常量，尽管该文件当前为空，但预留了扩展空间。

**可复用组件层（widgets/）** 包含可被多个页面重复使用的 UI 组件，包括底部导航栏组件 `app_bottom_nav.dart`、主按钮组件 `primary_button.dart`、次要按钮组件 `secondary_button.dart`、风险卡片组件 `risk_card.dart`、SOS 按钮组件 `sos_button.dart`、倒计时遮罩组件 `countdown_overlay.dart`、模拟通话对话框组件 `call_simulate_dialog.dart` 以及视频播放器对话框组件 `video_player_dialog.dart`。

## 三、核心模块详细说明

### 3.1 应用入口模块

`lib/main.dart` 是整个应用的入口文件，采用简化的启动方式。该文件导入了 `destination_safety_page.dart` 作为默认首页，并通过 `runApp` 函数启动 Flutter 应用。在 `MyApp` 组件中，配置了 Material 应用的基本属性：应用标题设置为「栖途」，主题配置使用粉色作为主色调，并将 `DestinationSafetyPage` 设置为初始首页组件。这种简化设计使得应用启动后直接进入目的地安全预警功能，方便用户快速查询旅行目的地的安全信息。

### 3.2 应用核心配置模块

`lib/app/app.dart` 定义了完整的应用根组件 `NestWayApp`。该组件继承自 `StatelessWidget`，在 `build` 方法中返回配置完整的 `MaterialApp`。组件的核心配置包括：设置 `debugShowCheckedModeBanner` 为 false 以隐藏调试模式横幅；定义主题数据 `ThemeData`，配置主色为黄色、背景色为淡紫色，并设置透明背景的 `AppBarTheme`；设置初始路由为首页 `AppRoutes.home`，并注册完整的路由表 `AppRoutes.routes`。这个配置模块是整个应用的全局设置中心，所有页面都共享这里定义的主题和路由配置。

### 3.3 路由管理模块

`lib/routes/app_routes.dart` 集中管理应用的路由系统。该模块使用静态常量和静态映射表两种形式组织路由信息。路由常量采用 `const String` 声明，包括 `home`（`/`）、`sos`（`/sos`）、`sosHistory`（`/sos_history`）、`sendSosMessage`（`/send_sos_message`）、`escort`（`/escort`）、`escortProgress`（`/escort_progress`）、`success`（`/success`）、`timeout`（`/timeout`）、`safety`（`/safety`）和 `profile`（`/profile`）共十个路由。路由映射表 `routes` 是一个 `Map<String, WidgetBuilder>` 类型的数据结构，将每个路由路径关联到对应的页面组件构造器函数。通过 `Navigator.pushNamed` 和 `Navigator.pushReplacementNamed` 方法，可以在应用中实现页面导航和路由切换。

### 3.4 SOS 服务模块

`lib/services/sos_service.dart` 是应用的核心业务服务类，实现了 SOS 紧急求助功能的所有业务逻辑。该类采用单例模式设计，通过私有构造函数 `_internal()` 和工厂构造函数 `factory SosService()` 确保全局只有一个实例。

`makePhoneCall(String phoneNumber)` 方法用于拨打电话功能。该方法首先尝试通过 `MethodChannel` 调用原生平台的拨打电话功能，如果调用失败则将电话号码复制到剪贴板，作为降级处理策略。这种设计确保了在无法直接调用系统电话功能的情况下，用户仍能通过其他方式获取电话号码。

`callEmergencyServices()` 方法封装了对紧急报警电话 110 的拨打操作，内部调用 `makePhoneCall` 方法实现。

`getCurrentLocation()` 方法用于获取用户当前位置。该方法同样通过 `MethodChannel` 与原生平台通信，调用 `getCurrentLocation` 方法获取经纬度信息。如果获取失败，返回包含空值的经纬度对象。

`generateLocationShareUrl(double lat, double lng, String? description)` 方法生成高德地图的位置分享链接。该方法接收纬度、经度和位置描述作为参数，使用 `Uri.encodeComponent` 对描述文本进行 URL 编码，生成符合高德地图 URL Scheme 格式的位置分享链接。

`reportSosEvent()` 方法用于上报 SOS 事件到服务器。该方法接收事件类型、位置描述、经纬度等参数，通过 `Future.delayed` 模拟网络请求延迟（500毫秒），成功时返回 true，失败时返回 false。

`shareLocation()` 方法用于分享用户位置。该方法首先生成位置分享链接，然后将链接复制到剪贴板，供用户粘贴发送给紧急联系人。

`getSosHistory()` 方法用于获取 SOS 求助历史记录。该方法返回模拟数据 `mockSosLogs`，用于展示求助历史页面。开发阶段使用模拟数据，生产环境应替换为真实的 API 调用。

`getEmergencyContacts()` 方法用于获取用户的紧急联系人列表，返回模拟数据 `mockContacts`。该数据包含联系人的基本信息，包括姓名和电话号码。

`triggerSos()` 方法是触发 SOS 求救的核心方法。该方法接收紧急联系人列表和位置描述作为参数，首先获取用户当前位置，然后并发执行三个操作：上报 SOS 事件到服务器、拨打第一个紧急联系人的电话、分享位置链接给紧急联系人。使用 `Future.wait` 实现并发调用，确保所有操作能够同时执行，提高求助响应效率。

### 3.5 首页模块

`lib/pages/home/home_page.dart` 是应用的主页组件，采用无状态组件 `StatelessWidget` 实现。页面布局从上到下分为三个区域：顶部区域显示应用 Logo「NestWay」和当前城市安全状态「深圳 · 当前安全」；中间区域是核心功能入口「虚拟护送」按钮，点击后导航到护送设置页面；底部区域是底部导航栏组件 `AppBottomNav`，当前选中状态为首页。

页面使用 `SafeArea` 组件确保内容显示在安全区域内，避免被系统状态栏和导航栏遮挡。`Spacer` 组件用于分配弹性空间，将内容垂直居中显示。`Navigator.pushReplacementNamed` 方法用于替换当前路由栈中的首页，实现返回时退出应用而非返回首页的导航效果。

### 3.6 SOS 紧急求助模块

`lib/pages/sos/sos_page.dart` 是 SOS 功能的核心页面，采用有状态组件 `StatefulWidget` 实现，以支持交互过程中的状态变化。该页面提供三个求助选项：紧急报警（红色卡片）、共享位置给联系人（黄色卡片）、播放安全视频（蓝色卡片）。

紧急报警功能通过 `GestureDetector` 组件实现长按检测，长按 3 秒后可触发报警功能。长按过程中显示圆形进度指示器，实时反馈按压进度（0% 至 100%）。进度达到 100% 后，弹出确认对话框询问用户是否确认拨打 110。确认后调用 `_dial110()` 方法尝试拨打报警电话，该方法首先尝试使用 URL Scheme 方式拨打电话，如果失败则尝试通过 MethodChannel 调用原生拨打电话功能。

共享位置功能通过点击黄色风险卡片触发，导航到 `SendSosMessagePage` 页面。

播放安全视频功能通过 `_playAttentionVideo()` 方法实现，调用 `CallSimulateDialog.show` 显示模拟通话对话框。

SOS 历史记录按钮位于导航栏右侧，点击后导航到 `SosHistoryPage` 页面查看历史求助记录。

页面底部提供「取消」和「我很安全」两个操作按钮，点击后均返回首页。「我很安全」按钮提供了视觉反馈，让用户确认自己处于安全状态。

### 3.7 SOS 历史记录模块

`lib/pages/sos/sos_history_page.dart` 展示用户的 SOS 求助历史记录。该页面使用 `SosService` 获取历史数据，采用下拉刷新机制提供数据更新功能。页面支持四种求助类型的展示：语音通话（绿色图标）、短信（蓝色图标）、视频通话（橙色图标）以及其他类型（红色图标）。

历史列表使用 `ListView.builder` 高效构建，每个列表项包含类型图标、时间信息和位置描述。列表项使用 `Container` 包装，提供白色背景、圆角边框和轻微阴影的视觉效果。右侧的状态指示点表示该求助记录的处理状态（绿色表示已完成）。

### 3.8 发送 SOS 消息模块

`lib/pages/sos/send_sos_message_page.dart` 提供发送求助短信的功能界面。用户可以通过下拉框选择紧急联系人，预览自动生成的求助短信内容，确认无误后点击发送按钮。

短信内容模板包含求助者昵称「用户昵称」、当前位置「深圳市福田区安发大厦 SUNNY SAPCE」以及应用名称「Nestway app」。发送成功后显示带有绿色对勾的成功对话框，两秒后自动关闭并返回 SOS 页面。

### 3.9 虚拟护送模块

`lib/pages/escort/escort_page.dart` 提供虚拟护送功能的设置界面。用户可以设置起点位置（当前位置）、终点位置（目的地）以及预计时间。点击「开始护送」按钮后，导航到护送进度页面。

该页面采用简化的输入卡片设计，每个输入卡片包含图标和提示文本。页面结构清晰，使用 `Spacer` 组件将按钮区域固定在页面底部，确保在不同屏幕尺寸下都能获得良好的用户体验。

### 3.10 护送进度模块

`lib/pages/escort/progress_page.dart` 展示虚拟护送的进行状态。该页面包含四个主要区域：顶部状态栏显示护送进行中状态和实时位置指示；路径卡片显示起点和终点信息；倒计时卡片显示剩余时间（如「14分52秒」）和安全提示信息；紧急联系人卡片显示联系人姓名和电话号码，提供一键呼叫功能。底部提供「暂停护送」操作和「安全打卡」功能，点击安全打卡后导航到成功页面。

### 3.11 目的地安全预警模块

`lib/pages/safety/destination_safety_page.dart` 提供基于 AI 的目的地安全分析功能。用户输入城市名称后，应用调用 DeepSeek API 生成该城市的安全报告。

该页面使用 `TextField` 接收用户输入的城市名称，配合「AI 分析」按钮触发分析请求。分析过程显示加载指示器，完成后展示安全卡片。安全卡片包含以下信息：城市名称和安全评分（0-100分）、整体治安评级（低/中/高风险）、夜间出行建议、街道情况、住宿注意事项、报警电话（110）、急救电话（120）以及女性旅行者反馈摘要。

API 调用使用环境变量 `DEEPSEEK_API_KEY` 存储密钥，确保密钥安全。请求配置包括使用 `deepseek-chat` 模型、温度参数设为 0.1 以获得确定性回答、最大 token 数为 2000、以及 JSON 对象格式响应。

### 3.12 个人中心模块

`lib/pages/profile/profile_page.dart` 提供用户个人信息和紧急联系人的管理功能。页面顶部显示用户卡片，包含头像、昵称和账号验证状态。点击编辑图标可以修改用户昵称。守护状态卡片显示用户使用应用的天数。紧急联系人卡片列出用户添加的所有紧急联系人，提供添加和删除功能。底部提供「退出当前账号」选项。

### 3.13 可复用组件

**app_bottom_nav.dart** 提供底部导航栏组件，支持首页、SOS、个人中心三个导航选项。当前选中项通过 `currentIndex` 参数指定。

**primary_button.dart** 提供主按钮组件，用于突出展示核心操作按钮，如「开始护送」按钮。该组件接收按钮文本、尺寸和点击回调作为参数。

**secondary_button.dart** 提供次要按钮组件，用于展示次要操作选项。

**risk_card.dart** 提供风险卡片组件，用于展示不同类型的风险提示和功能入口，如紧急报警、共享位置等。卡片支持自定义颜色、标题、描述文字、图标和点击回调。

**sos_button.dart** 提供 SOS 专用按钮组件，用于紧急求助场景。

**countdown_overlay.dart** 提供倒计时遮罩组件，用于长按操作时的进度反馈。

**call_simulate_dialog.dart** 提供模拟通话对话框组件，用于播放安全提示视频或模拟通话功能。

**video_player_dialog.dart** 提供视频播放器对话框组件，使用 `video_player` 依赖实现视频播放功能。

## 四、数据模型

### 4.1 用户数据模型

用户数据存储在 `lib/mock/mock_user.dart` 中，定义了以下字段：`id`（用户编号）、`name`（用户昵称）、`avatar_url`（头像 URL）、`phone`（手机号码）、`is_verified`（账号是否已验证）以及 `created_at`（账号创建时间）。示例数据中，用户范颖的账号创建于 2024 年 4 月 1 日。

### 4.2 紧急联系人数据模型

紧急联系人数据存储在 `lib/mock/mock_contacts.dart` 中，每个联系人包含以下字段：`id`（联系人编号）、`user_id`（关联用户编号）、`name`（联系人姓名）、`phone`（电话号码）以及 `sort_order`（排序顺序）。示例数据包含妈妈、爸爸和室友三位紧急联系人。

### 4.3 SOS 日志数据模型

SOS 日志数据存储在 `lib/mock/mock_sos_logs.dart` 中，每条日志包含以下字段：`id`（日志编号）、`type`（求助类型，包括 call、sms、video 等）、`triggered_at`（触发时间，ISO 8601 格式）、`location_description`（位置描述）、`latitude`（纬度）和 `longitude`（经度）。

### 4.4 目的地安全数据模型

目的地安全数据由 AI 实时生成，包含以下字段：`safety_score`（安全评分，0-100 整数）、`risk_level`（风险等级，包括低、中、高）、`night_advice`（夜间出行建议）、`street_condition`（街道情况描述）、`accommodation_tips`（住宿安全建议）、`police_phone`（报警电话）、`ambulance_phone`（急救电话）以及 `women_review_summary`（女性旅行者评价摘要）。

## 五、平台集成说明

### 5.1 MethodChannel 通信

应用通过 Flutter 的 `MethodChannel` 与原生平台进行通信，实现平台特定的功能。已定义的通道包括：`com.nestway/phone` 用于电话功能，包括 `makePhoneCall`（拨打电话）和 `openDialer`（打开拨号盘）两个方法；`com.nestway/location` 用于位置功能，包括 `getCurrentLocation`（获取当前位置）方法。这些通道定义在 `lib/services/sos_service.dart` 中，供 `SosService` 类调用。

### 5.2 Android 平台配置

Android 平台的入口文件位于 `android/app/src/main/kotlin/com/example/solotrip/MainActivity.kt`，使用 Kotlin 语言编写。`AndroidManifest.xml` 文件中需要配置拨打电话和获取位置所需的权限。

### 5.3 iOS 平台配置

iOS 平台使用 Swift 语言编写入口代码，文件位于 `ios/Runner/AppDelegate.swift`。iOS 平台同样需要配置相应的权限声明才能实现电话和位置功能。

## 六、项目运行指南

### 6.1 环境准备

运行本项目前，需要确保开发环境满足以下要求。首先，需要安装 Flutter SDK，版本应不低于 3.0.0，建议使用最新的稳定版本。其次，需要配置 Flutter 环境变量，确保 `flutter` 命令可以在终端中执行。再次，根据目标运行平台，需要安装相应的原生开发工具：Android 平台需要 Android Studio 和 Android SDK；iOS 平台需要 Xcode（仅 macOS 可用）；Windows 平台需要 Visual Studio 2019 或更高版本；macOS 平台需要 Xcode；Linux 平台需要 GTK 开发环境。最后，如果使用 AI 安全分析功能，需要获取 DeepSeek API Key 并配置到运行环境变量中。

### 6.2 依赖安装

在项目根目录下执行以下命令安装项目依赖：

```bash
flutter pub get
```

该命令会根据 `pubspec.yaml` 中的依赖声明下载并安装所有必需的包，包括 Flutter SDK、video_player 和 http 等。安装完成后，`pubspec.lock` 文件会记录所有依赖的具体版本信息。

### 6.3 运行应用

安装依赖后，可以使用以下命令运行应用。根据目标平台选择相应的命令：

```bash
# 运行到默认设备（如果有连接设备或模拟器）
flutter run

# 运行到 Android 设备或模拟器
flutter run -d android

# 运行到 iOS 设备或模拟器（仅 macOS）
flutter run -d ios

# 运行到 Web 浏览器
flutter run -d chrome
```

### 6.4 配置 DeepSeek API

如果需要使用 AI 目的地安全分析功能，需要在运行应用时配置 API Key：

```bash
flutter run --dart-define=DEEPSEEK_API_KEY=你的密钥
```

或者在启动应用后在界面上看到相应提示后进行配置。API Key 可以通过环境变量或命令行参数的方式提供，不会硬编码到代码中。

### 6.5 运行测试

项目包含完整的单元测试和组件测试，位于 `test/` 目录下。可以使用以下命令运行测试：

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/sos_service_test.dart
```

测试文件包括 `sos_service_test.dart`（SOS 服务单元测试）、`app_bottom_nav_test.dart`（底部导航栏测试）、`primary_button_test.dart`（主按钮测试）、`risk_card_test.dart`（风险卡片测试）、`sos_button_test.dart`（SOS 按钮测试）、`sos_history_page_test.dart`（SOS 历史页面测试）、`pages_test.dart`（页面测试）、`widget_test.dart`（组件测试）以及 `functional_test.dart`（功能测试）。

### 6.6 构建发布

构建各平台安装包使用以下命令：

```bash
# 构建 Android APK
flutter build apk

# 构建 Android App Bundle（用于 Google Play）
flutter build appbundle

# 构建 iOS 应用（仅 macOS，需要 Xcode）
flutter build ios

# 构建 Web 应用
flutter build web
```

## 七、开发指南

### 7.1 代码风格

本项目遵循 Flutter 官方的代码风格指南，使用 `flutter_lints` 规则进行代码检查。推荐使用 `flutter analyze` 命令检查代码质量。

### 7.2 新增页面

新增页面时，需要在 `lib/pages/` 目录下创建对应的 Dart 文件。建议按功能模块组织页面文件。新增页面后，需要在 `lib/routes/app_routes.dart` 中添加路由定义，将页面组件注册到路由表中。

### 7.3 新增组件

新增可复用组件时，建议在 `lib/widgets/` 目录下创建独立的 Dart 文件。组件应尽量保持职责单一，可以通过参数接收数据和回调函数，提高组件的可复用性。

### 7.4 新增服务

如果需要添加新的业务服务，建议在 `lib/services/` 目录下创建新的服务类。服务类应采用单例模式或依赖注入方式进行管理，保持与 UI 层的解耦。

## 八、文件目录结构

以下是项目的完整文件目录结构及其说明：

```
d:\桌面\solotrip/
├── android/                    # Android 平台原生代码
│   └── app/src/main/           # Android 主应用代码
│       ├── kotlin/             # Kotlin 源代码
│       │   └── com/example/solotrip/MainActivity.kt
│       └── res/                # Android 资源文件
│           ├── drawable/       # 图片资源
│           ├── mipmap-*/       # 应用图标
│           └── values/         # 字符串和样式资源
├── ios/                       # iOS 平台原生代码
│   └── Runner/                # iOS 应用入口
│       ├── AppDelegate.swift   # iOS 应用代理
│       └── Assets.xcassets/    # iOS 资源目录
├── lib/                       # Flutter 核心代码
│   ├── app/                   # 应用核心配置
│   │   └── app.dart           # 应用根组件
│   ├── mock/                  # 测试数据
│   │   ├── mock_city_safety.dart
│   │   ├── mock_contacts.dart
│   │   ├── mock_sos_logs.dart
│   │   ├── mock_user.dart
│   │   └── mock_videos.dart
│   ├── pages/                 # 页面组件
│   │   ├── common/            # 通用页面
│   │   │   ├── success_page.dart
│   │   │   └── timeout_page.dart
│   │   ├── escort/            # 虚拟护送页面
│   │   │   ├── escort_page.dart
│   │   │   └── progress_page.dart
│   │   ├── home/              # 首页
│   │   │   └── home_page.dart
│   │   ├── profile/           # 个人中心
│   │   │   └── profile_page.dart
│   │   ├── safety/            # 安全相关页面
│   │   │   ├── destination_safety_page.dart
│   │   │   └── safety_page.dart
│   │   └── sos/               # SOS 紧急求助页面
│   │       ├── send_sos_message_page.dart
│   │       ├── sos_history_page.dart
│   │       └── sos_page.dart
│   ├── routes/                # 路由配置
│   │   └── app_routes.dart
│   ├── services/              # 业务服务
│   │   └── sos_service.dart
│   ├── utils/                 # 工具函数
│   │   └── constants.dart
│   ├── widgets/               # 可复用组件
│   │   ├── app_bottom_nav.dart
│   │   ├── call_simulate_dialog.dart
│   │   ├── countdown_overlay.dart
│   │   ├── primary_button.dart
│   │   ├── risk_card.dart
│   │   ├── secondary_button.dart
│   │   ├── sos_button.dart
│   │   └── video_player_dialog.dart
│   └── main.dart              # 应用入口
├── test/                      # 测试代码
│   ├── app_bottom_nav_test.dart
│   ├── functional_test.dart
│   ├── pages_test.dart
│   ├── primary_button_test.dart
│   ├── risk_card_test.dart
│   ├── sos_button_test.dart
│   ├── sos_history_page_test.dart
│   ├── sos_service_test.dart
│   └── widget_test.dart
├── web/                       # Web 平台代码
├── windows/                   # Windows 平台代码
├── linux/                     # Linux 平台代码
├── macos/                     # macOS 平台代码
├── pubspec.yaml               # Flutter 依赖配置
├── pubspec.lock               # 依赖版本锁定
└── README.md                  # 项目说明
```

本 Wiki 文档将随项目更新而持续维护，记录项目的架构演进、功能扩展和技术变更。