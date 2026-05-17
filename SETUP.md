# 开发环境搭建指南

> 适用于首次拉取代码的开发者。5 分钟即可完成环境搭建。

## 1. 前置要求

| 工具 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.x+ | `flutter --version` 确认 |
| Android Studio / VS Code | 最新 | 带 Flutter 插件 |
| Git | 任意 | `git clone` 用 |

## 2. 克隆并安装依赖

```bash
git clone https://github.com/xixixiFan/NestWay.git
cd NestWay
flutter pub get
```

## 3. 环境变量配置（可选）

App 中 Supabase 连接信息已硬编码在源码中，**无需额外配置即可运行**。

如果你想本地覆盖配置：

```bash
cp .env.example .env
# 编辑 .env 填入实际值
```

`.env` 已在 `.gitignore` 中，不会被提交到 Git。

## 4. 数据库初始化

App 连接的是项目统一的 Supabase 实例，数据库表已建好，**无需本地建表**。

如需执行新的 SQL 脚本：
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard/project/fbnctnhjcjkbmmvcuqxh)
2. 左侧菜单 → **SQL Editor**
3. 粘贴 SQL 文件内容，点击 **Run**

## 5. 运行 App

```bash
flutter run
```

或使用 IDE 的运行按钮。

---

## 常见问题

### Q: 登录收不到验证码？
Supabase OTP 功能需要验证手机号归属。开发阶段可查看 Supabase Dashboard → Authentication → Users 中的测试用户。

### Q: 地图/定位不显示？
需要在高德开放平台申请 API Key，配置到 AndroidManifest.xml 和 Info.plist 中。

### Q: Service Role Key 是什么？我需要吗？
Service Role Key 是 Supabase 的超级管理员密钥（绕过 RLS 权限检查）。**日常 App 开发不需要它**。仅当你需要用 CLI 工具直连数据库执行管理操作时才需要——而且不要在客户端代码中使用它。
