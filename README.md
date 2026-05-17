# NestWay（栖途）

> 女性独旅安全 Flutter App — 虚拟护送、SOS 紧急求助、AI 城市安全分析

## 技术栈

| 层 | 技术 |
|---|------|
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Provider |
| 后端 | Supabase (PostgreSQL + Auth) |
| AI | DeepSeek API（城市安全分析）|
| 地图 | 高德 Flutter 地图 (amap_flutter_map) |
| 平台 | Android / iOS |

## 功能

- **SOS 紧急求助** — 长按报警、位置共享、安全视频播放、模拟来电、求助历史
- **虚拟护送** — 实时定位跟踪、ETA 倒计时、安全打卡、超时预警
- **紧急联系人** — 完整 CRUD，Supabase 持久化
- **城市安全分析** — DeepSeek AI 驱动的目的地安全评分
- **手机验证码登录** — Supabase Auth (OTP)

## 快速开始

详见 [SETUP.md](SETUP.md) — 5 分钟搭建指南。

```bash
git clone https://github.com/xixixiFan/NestWay.git
cd NestWay
flutter pub get
flutter run
```

> App 已接入项目统一的 Supabase 实例，无需额外配置即可运行。

## 项目结构

```
lib/
├── main.dart                  # 入口，Supabase 初始化
├── app/
│   └── app.dart               # MaterialApp + 路由表
├── pages/
│   ├── home/                  # 首页（品牌 + 功能入口 + 目的地搜索）
│   ├── auth/                  # 手机验证码登录
│   ├── sos/                   # SOS 求助 + 历史记录
│   ├── escort/                # 虚拟护送（出发/进度/成功/超时）
│   ├── profile/               # 个人中心 + 紧急联系人
│   └── safety/                # 城市安全分析（DeepSeek AI）
├── widgets/                   # 可复用组件
├── services/                  # Supabase / SOS / 定位服务
├── mock/                      # 开发用 Mock 数据
└── routes/                    # 路由常量
```

## 相关文档

- [SETUP.md](SETUP.md) — 开发环境搭建指南
- [docs/FEATURE_COMPLETION_REPORT.md](docs/FEATURE_COMPLETION_REPORT.md) — 功能完成度分析报告
- [MVP_测试指南.md](MVP_测试指南.md) — MVP 测试指南
