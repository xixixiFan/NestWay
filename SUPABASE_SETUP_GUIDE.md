# Supabase 后端服务配置指南

**项目**：栖途 NestWay  
**Supabase 项目**：`fbnctnhjcjkbmmvcuqxh`  
**配置日期**：2026-05-16

---

## 目录

1. 在 Supabase Dashboard 中执行 SQL 脚本
2. 获取 API 密钥
3. 配置 Flutter 应用
4. 验证连接

---

## 1. 在 Supabase Dashboard 中执行 SQL 脚本

### 1.1 登录 Supabase

1. 访问 [Supabase Dashboard](https://app.supabase.com/)
2. 登录你的账号
3. 选择项目：`fbnctnhjcjkbmmvcuqxh`

### 1.2 打开 SQL Editor

1. 在左侧菜单中点击 **SQL Editor**
2. 点击 **New Query** 按钮

### 1.3 执行初始化脚本

复制 [`supabase_init.sql`](file:///e:/ai/solotrip/NestWay/supabase_init.sql) 文件中的所有内容，粘贴到 SQL Editor 中，然后点击 **Run** 按钮执行。

**脚本将完成以下操作**：
- ✅ 创建 `users` 表
- ✅ 创建 `emergency_contacts` 表
- ✅ 创建 `sos_logs` 表
- ✅ 创建 `escort_tasks` 表
- ✅ 创建必要的索引
- ✅ 插入测试数据（用户范颖、3个紧急联系人、3条SOS日志）
- ✅ 配置 Row Level Security 策略

### 1.4 验证执行结果

执行成功后，你应该看到：
```
┌──────────────────────────────────────┐
│ result                               │
├──────────────────────────────────────┤
│ 数据库初始化完成，已插入测试数据       │
└──────────────────────────────────────┘
```

---

## 2. 获取 API 密钥

### 2.1 打开 API 设置

1. 点击左侧菜单 **Settings**
2. 点击 **API**

### 2.2 复制密钥

你会看到以下信息：

| 密钥类型 | 用途 | 状态 |
|---------|------|------|
| Project URL | 数据库连接地址 | ✅ 已配置 |
| anon public | 客户端使用的公开密钥 | ⬜ 需要复制 |
| service_role | 服务端密钥（保密） | ⬜ 需要复制 |

**复制 anon public 密钥**（以 `eyJ...` 开头）

---

## 3. 配置 Flutter 应用

### 3.1 更新 SupabaseService

打开 [`lib/services/supabase_service.dart`](file:///e:/ai/solotrip/NestWay/lib/services/supabase_service.dart)，更新 `initialize` 方法中的 `anonKey`：

```dart
static Future<void> initialize() async {
  await Supabase.initialize(
    url: 'https://fbnctnhjcjkbmmvcuqxh.supabase.co',
    anonKey: '粘贴你的 anon public 密钥',
  );
  _instance = Supabase.instance.client;
}
```

### 3.2 安装依赖

在终端中执行：

```bash
flutter pub get
```

### 3.3 运行应用

```bash
flutter run
```

---

## 4. 验证连接

### 4.1 检查 Table Editor

在 Supabase Dashboard 中：
1. 点击左侧菜单 **Table Editor**
2. 你应该能看到以下表：
   - `users`
   - `emergency_contacts`
   - `sos_logs`
   - `escort_tasks`

### 4.2 检查测试数据

点击 `users` 表，你应该能看到用户 "范颖" 的记录。

### 4.3 测试应用功能

1. 打开应用
2. 进入 SOS 页面
3. 查看历史记录，应该能看到3条测试SOS记录
4. 测试紧急联系人显示

---

## 常见问题

### Q1: SQL 执行失败，显示表已存在

这可能是因为表已经存在。可以先删除现有表再重新创建：

```sql
-- 删除现有表（按依赖顺序）
DROP TABLE IF EXISTS escort_tasks CASCADE;
DROP TABLE IF EXISTS sos_logs CASCADE;
DROP TABLE IF EXISTS emergency_contacts CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 然后重新执行初始化脚本
```

### Q2: RLS 策略冲突

如果遇到 RLS 权限问题，可以暂时禁用 RLS 进行测试：

```sql
-- 禁用所有表的 RLS
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts DISABLE ROW LEVEL SECURITY;
ALTER TABLE sos_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE escort_tasks DISABLE ROW LEVEL SECURITY;

-- 测试完成后重新启用
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ... 其他表同理
```

### Q3: 找不到 anon key

anon key 的格式是 `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...`，位于 **Settings > API > Project API keys** 部分。

---

## 下一步

配置完成后，你可以：

1. **启用手机号认证**：进入 Authentication > Settings > Phone，启用 "Enable phone sign-ins"
2. **测试用户注册**：实现用户注册和登录功能
3. **集成真实位置服务**：连接高德地图或其他位置服务
4. **实现 SOS 通知**：配置短信通知服务

---

**配置完成！** 🎉