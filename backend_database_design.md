# 栖途 NestWay - Supabase 后端数据库设计文档

**文档版本**：v1.1（适配模拟数据）  
**创建日期**：2026-05-16  
**适用项目**：栖途 NestWay 女性独旅安全 App  
**数据库平台**：Supabase (PostgreSQL)

---

## 目录

1. 概述
2. 数据库表设计
   2.1 users 表（用户信息表）
   2.2 emergency_contacts 表（紧急联系人表）
   2.3 sos_logs 表（SOS 事件记录表）
   2.4 escort_tasks 表（虚拟护送任务表）
3. Row Level Security (RLS) 配置
4. 索引设计
5. 认证配置
6. 前端集成配置
7. SQL 初始化脚本

---

## 1. 概述

本文档定义了栖途 NestWay 应用的后端数据库结构，基于 Supabase PostgreSQL 构建。数据库设计遵循以下原则：

- **安全性**：使用 Row Level Security 确保用户只能访问自己的数据
- **完整性**：通过外键约束保证数据一致性
- **可扩展性**：预留字段便于未来功能扩展
- **性能**：合理设计索引优化查询效率
- **兼容性**：与现有前端模拟数据结构保持一致

---

## 2. 数据库表设计

### 2.1 users 表（用户信息表）

| 字段名 | 类型 | 约束 | 说明 | 模拟数据参考 |
|--------|------|------|------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 用户唯一标识 | `"id": 1` |
| name | TEXT | NOT NULL | 用户昵称 | `"name": "范颖"` |
| phone | TEXT | UNIQUE, NOT NULL | 用户手机号 | `"phone": "13800138000"` |
| avatar_url | TEXT | NULL | 用户头像 URL | `"avatar_url": ""` |
| is_verified | BOOLEAN | DEFAULT false | 账号是否已验证 | `"is_verified": true` |
| created_at | TIMESTAMP | DEFAULT NOW() | 创建时间 | `"created_at": "2024-04-01T10:00:00Z"` |

**ER 图表示**：
```
┌─────────────────────────────────────────┐
│               users                     │
├─────────────────────────────────────────┤
│ id (INT) ◄───────────────────── PK     │
│ name (TEXT)                            │
│ phone (TEXT) ─────── UNIQUE ────────►  │
│ avatar_url (TEXT)                      │
│ is_verified (BOOLEAN)                  │
│ created_at (TIMESTAMP)                 │
└─────────────────────────────────────────┘
```

**业务说明**：
- 手机号作为唯一标识，用于短信认证和紧急联系人通知
- `is_verified` 字段用于标记用户是否完成手机号验证

---

### 2.2 emergency_contacts 表（紧急联系人表）

| 字段名 | 类型 | 约束 | 说明 | 模拟数据参考 |
|--------|------|------|------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 联系人唯一标识 | `"id": 1` |
| user_id | INT | REFERENCES users(id) ON DELETE CASCADE | 关联用户 ID | `"user_id": 1` |
| name | TEXT | NOT NULL | 联系人姓名 | `"name": "妈妈"` |
| phone | TEXT | NOT NULL | 联系人手机号 | `"phone": "13900000001"` |
| sort_order | INT | DEFAULT 0 | 排序顺序 | `"sort_order": 1` |
| created_at | TIMESTAMP | DEFAULT NOW() | 创建时间 | （模拟数据中缺失，自动生成） |

**ER 图表示**：
```
┌─────────────────────────────────────────┐
│           emergency_contacts            │
├─────────────────────────────────────────┤
│ id (INT) ◄──────────────────────── PK   │
│ user_id (INT) ───────► REFERENCES users(id) │
│ name (TEXT)                            │
│ phone (TEXT)                           │
│ sort_order (INT)                       │
│ created_at (TIMESTAMP)                 │
└─────────────────────────────────────────┘
```

**业务说明**：
- 外键关联 users 表，用户删除时级联删除联系人
- `sort_order` 用于控制联系人显示顺序，SOS 时优先通知排序靠前的联系人
- `created_at` 在模拟数据中缺失，数据库自动生成默认值

---

### 2.3 sos_logs 表（SOS 事件记录表）

| 字段名 | 类型 | 约束 | 说明 | 模拟数据参考 |
|--------|------|------|------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 事件唯一标识 | `"id": 1` |
| user_id | INT | REFERENCES users(id) ON DELETE CASCADE | 关联用户 ID | `"user_id": 1` |
| type | TEXT | CHECK IN ('call', 'sms', 'video', 'sos'), NOT NULL | 事件类型 | `"type": "call"` |
| location_description | TEXT | NULL | 位置描述 | `"location_description": "东京涩谷站附近"` |
| latitude | DOUBLE PRECISION | NULL | 纬度坐标 | （模拟数据中缺失，可选） |
| longitude | DOUBLE PRECISION | NULL | 经度坐标 | （模拟数据中缺失，可选） |
| triggered_at | TIMESTAMP | DEFAULT NOW() | 触发时间 | `"triggered_at": "2025-05-01T22:10:00Z"` |

**ER 图表示**：
```
┌─────────────────────────────────────────┐
│               sos_logs                  │
├─────────────────────────────────────────┤
│ id (INT) ◄──────────────────────── PK   │
│ user_id (INT) ───────► REFERENCES users(id) │
│ type (TEXT) ───────► CHECK IN(call,sms,video,sos) │
│ location_description (TEXT)            │
│ latitude (DOUBLE PRECISION)            │
│ longitude (DOUBLE PRECISION)           │
│ triggered_at (TIMESTAMP)               │
└─────────────────────────────────────────┘
```

**业务说明**：
- `type` 字段枚举值：
  - `call`：语音通话求助
  - `sms`：短信求助
  - `video`：视频通话求助
  - `sos`：一键 SOS 求助
- `latitude` 和 `longitude` 在模拟数据中缺失，设计为可选字段

---

### 2.4 escort_tasks 表（虚拟护送任务表）

| 字段名 | 类型 | 约束 | 说明 | 模拟数据状态 |
|--------|------|------|------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 任务唯一标识 | （暂无模拟数据） |
| user_id | INT | REFERENCES users(id) ON DELETE CASCADE | 关联用户 ID | （暂无模拟数据） |
| start_location | TEXT | NULL | 起点位置描述 | （暂无模拟数据） |
| end_location | TEXT | NULL | 终点位置描述 | （暂无模拟数据） |
| estimated_duration | INT | NULL | 预计时长（分钟） | （暂无模拟数据） |
| status | TEXT | CHECK IN ('active', 'completed', 'timeout'), DEFAULT 'active' | 任务状态 | （暂无模拟数据） |
| started_at | TIMESTAMP | NULL | 开始时间 | （暂无模拟数据） |
| completed_at | TIMESTAMP | NULL | 完成时间 | （暂无模拟数据） |
| last_location_lat | DOUBLE PRECISION | NULL | 最后上报纬度 | （暂无模拟数据） |
| last_location_lng | DOUBLE PRECISION | NULL | 最后上报经度 | （暂无模拟数据） |
| created_at | TIMESTAMP | DEFAULT NOW() | 创建时间 | （暂无模拟数据） |

**ER 图表示**：
```
┌─────────────────────────────────────────┐
│             escort_tasks               │
├─────────────────────────────────────────┤
│ id (INT) ◄──────────────────────── PK   │
│ user_id (INT) ───────► REFERENCES users(id) │
│ start_location (TEXT)                  │
│ end_location (TEXT)                    │
│ estimated_duration (INT)               │
│ status (TEXT) ───────► CHECK IN(active,completed,timeout) │
│ started_at (TIMESTAMP)                 │
│ completed_at (TIMESTAMP)               │
│ last_location_lat (DOUBLE PRECISION)   │
│ last_location_lng (DOUBLE PRECISION)   │
│ created_at (TIMESTAMP)                 │
└─────────────────────────────────────────┘
```

**业务说明**：
- `status` 字段枚举值：
  - `active`：护送进行中
  - `completed`：用户安全到达并打卡
  - `timeout`：超时未完成（触发告警）
- 该表暂无对应模拟数据，预留用于未来功能扩展

---

## 3. Row Level Security (RLS) 配置

### 3.1 安全策略概述

所有数据表均启用 Row Level Security，确保用户只能访问和操作自己的数据。

### 3.2 详细策略配置

#### 3.2.1 users 表策略

```sql
-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的数据
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid()::TEXT = id::TEXT);
```

#### 3.2.2 emergency_contacts 表策略

```sql
-- 启用 RLS
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- 用户可以插入自己的联系人
CREATE POLICY "Users can insert their own contacts" ON emergency_contacts
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以查看自己的联系人
CREATE POLICY "Users can view their own contacts" ON emergency_contacts
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以更新自己的联系人
CREATE POLICY "Users can update their own contacts" ON emergency_contacts
  FOR UPDATE USING (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以删除自己的联系人
CREATE POLICY "Users can delete their own contacts" ON emergency_contacts
  FOR DELETE USING (auth.uid()::TEXT = user_id::TEXT);
```

#### 3.2.3 sos_logs 表策略

```sql
-- 启用 RLS
ALTER TABLE sos_logs ENABLE ROW LEVEL SECURITY;

-- 用户可以插入自己的 SOS 日志
CREATE POLICY "Users can insert their own sos logs" ON sos_logs
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以查看自己的 SOS 日志
CREATE POLICY "Users can view their own sos logs" ON sos_logs
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);
```

#### 3.2.4 escort_tasks 表策略

```sql
-- 启用 RLS
ALTER TABLE escort_tasks ENABLE ROW LEVEL SECURITY;

-- 用户可以插入自己的护送任务
CREATE POLICY "Users can insert their own escort tasks" ON escort_tasks
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以查看自己的护送任务
CREATE POLICY "Users can view their own escort tasks" ON escort_tasks
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);

-- 用户可以更新自己的护送任务
CREATE POLICY "Users can update their own escort tasks" ON escort_tasks
  FOR UPDATE USING (auth.uid()::TEXT = user_id::TEXT);
```

---

## 4. 索引设计

### 4.1 索引清单

| 表名 | 索引名 | 字段 | 类型 | 说明 |
|------|--------|------|------|------|
| users | idx_users_phone | phone | UNIQUE | 加速手机号查询 |
| users | idx_users_id | id | PRIMARY | 主键索引 |
| emergency_contacts | idx_contacts_user_id | user_id | NORMAL | 加速按用户查询联系人 |
| sos_logs | idx_sos_logs_user_id | user_id | NORMAL | 加速按用户查询日志 |
| sos_logs | idx_sos_logs_triggered_at | triggered_at | NORMAL | 加速按时间排序查询 |
| escort_tasks | idx_escort_user_id | user_id | NORMAL | 加速按用户查询任务 |
| escort_tasks | idx_escort_status | status | NORMAL | 加速按状态查询任务 |

### 4.2 索引创建 SQL

```sql
-- users 表索引（主键自动创建）
CREATE UNIQUE INDEX idx_users_phone ON users(phone);

-- emergency_contacts 表索引
CREATE INDEX idx_contacts_user_id ON emergency_contacts(user_id);

-- sos_logs 表索引
CREATE INDEX idx_sos_logs_user_id ON sos_logs(user_id);
CREATE INDEX idx_sos_logs_triggered_at ON sos_logs(triggered_at);

-- escort_tasks 表索引
CREATE INDEX idx_escort_user_id ON escort_tasks(user_id);
CREATE INDEX idx_escort_status ON escort_tasks(status);
```

---

## 5. 认证配置

### 5.1 认证方式

| 认证方式 | 状态 | 用途 |
|---------|------|------|
| Phone | ✅ 启用 | 手机号验证码登录（主要方式） |
| Email | ⬜ 禁用 | 邮箱登录（可选扩展） |
| OAuth | ⬜ 禁用 | 第三方登录（可选扩展） |

### 5.2 认证设置步骤

1. 登录 Supabase Dashboard
2. 进入 **Authentication** → **Settings**
3. 在 **Phone** 部分：
   - 启用 **Enable phone sign-ins**
   - 可配置短信模板（如需自定义）
4. 保存设置

### 5.3 用户 ID 映射说明

由于数据库使用 INT 类型的 `id` 字段，而 Supabase Auth 的 `auth.uid()` 返回 UUID，需要进行类型转换：

```sql
-- 在 RLS 策略中，auth.uid() 返回 UUID，需要转换为 TEXT 后与 INT 比较
auth.uid()::TEXT = user_id::TEXT
```

---

## 6. 前端集成配置

### 6.1 依赖配置

在 `pubspec.yaml` 中添加 Supabase Flutter SDK：

```yaml
dependencies:
  supabase_flutter: ^1.10.0
```

### 6.2 初始化配置

创建 `lib/services/supabase_service.dart`：

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _instance;

  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception('Supabase not initialized');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    _instance = Supabase.instance.client;
  }
}
```

### 6.3 应用入口配置

更新 `lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const NestWayApp());
}
```

### 6.4 运行命令

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 7. SQL 初始化脚本

以下是完整的数据库初始化 SQL 脚本，可直接在 Supabase SQL Editor 中执行：

```sql
-- ==============================================
-- 栖途 NestWay - 数据库初始化脚本
-- 版本：v1.1（适配模拟数据）
-- ==============================================

-- 1. 创建 users 表（适配模拟数据：id 使用 INT 类型）
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_users_phone ON users(phone);

-- 2. 创建 emergency_contacts 表（适配模拟数据：id/user_id 使用 INT 类型）
CREATE TABLE emergency_contacts (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contacts_user_id ON emergency_contacts(user_id);

-- 3. 创建 sos_logs 表（适配模拟数据：id/user_id 使用 INT 类型）
CREATE TABLE sos_logs (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('call', 'sms', 'video', 'sos')) NOT NULL,
  location_description TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  triggered_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sos_logs_user_id ON sos_logs(user_id);
CREATE INDEX idx_sos_logs_triggered_at ON sos_logs(triggered_at);

-- 4. 创建 escort_tasks 表（预留表，暂无模拟数据）
CREATE TABLE escort_tasks (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  start_location TEXT,
  end_location TEXT,
  estimated_duration INT,
  status TEXT CHECK (status IN ('active', 'completed', 'timeout')) DEFAULT 'active',
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  last_location_lat DOUBLE PRECISION,
  last_location_lng DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_escort_user_id ON escort_tasks(user_id);
CREATE INDEX idx_escort_status ON escort_tasks(status);

-- ==============================================
-- 初始化测试数据（与前端模拟数据保持一致）
-- ==============================================

-- 插入测试用户
INSERT INTO users (id, name, phone, avatar_url, is_verified, created_at)
VALUES (1, '范颖', '13800138000', '', true, '2024-04-01T10:00:00Z');

-- 插入测试紧急联系人
INSERT INTO emergency_contacts (id, user_id, name, phone, sort_order, created_at)
VALUES 
  (1, 1, '妈妈', '13900000001', 1, NOW()),
  (2, 1, '爸爸', '13900000002', 2, NOW()),
  (3, 1, '室友', '13900000003', 3, NOW());

-- 插入测试 SOS 日志
INSERT INTO sos_logs (id, user_id, type, location_description, triggered_at)
VALUES 
  (1, 1, 'call', '东京涩谷站附近', '2025-05-01T22:10:00Z'),
  (2, 1, 'sms', '新宿歌舞伎町', '2025-05-02T23:45:00Z'),
  (3, 1, 'video', '池袋西口', '2025-05-03T21:30:00Z');

-- ==============================================
-- Row Level Security 配置
-- ==============================================

-- users 表
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid()::TEXT = id::TEXT);

-- emergency_contacts 表
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own contacts" ON emergency_contacts
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can view their own contacts" ON emergency_contacts
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can update their own contacts" ON emergency_contacts
  FOR UPDATE USING (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can delete their own contacts" ON emergency_contacts
  FOR DELETE USING (auth.uid()::TEXT = user_id::TEXT);

-- sos_logs 表
ALTER TABLE sos_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own sos logs" ON sos_logs
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can view their own sos logs" ON sos_logs
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);

-- escort_tasks 表
ALTER TABLE escort_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own escort tasks" ON escort_tasks
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can view their own escort tasks" ON escort_tasks
  FOR SELECT USING (auth.uid()::TEXT = user_id::TEXT);
CREATE POLICY "Users can update their own escort tasks" ON escort_tasks
  FOR UPDATE USING (auth.uid()::TEXT = user_id::TEXT);

-- ==============================================
-- 初始化完成
-- ==============================================
SELECT '数据库初始化完成，已插入测试数据' AS result;
```

---

## 附录：数据关系图

```
┌─────────────────┐       ┌──────────────────────┐
│    users        │       │ emergency_contacts   │
│                 │ 1:N   │                      │
│ id (INT) ───────┼───────► user_id (INT)       │
│ name            │       │ name                 │
│ phone           │       │ phone                │
│ avatar_url      │       │ sort_order           │
│ is_verified     │       └──────────────────────┘
│ created_at      │
└────────┬────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐       ┌──────────────────────┐
│    sos_logs     │       │  escort_tasks        │
│                 │       │                      │
│ user_id (INT) ◄─┴───────┤ user_id (INT)       │
│ type            │       │ start_location       │
│ location_desc   │       │ end_location         │
│ latitude        │       │ estimated_duration   │
│ longitude       │       │ status               │
│ triggered_at    │       │ started_at           │
└─────────────────┘       │ completed_at         │
                          │ last_location_lat    │
                          │ last_location_lng    │
                          └──────────────────────┘
```

---

## 附录：模拟数据与数据库映射表

| 模拟数据文件 | 数据库表 | 状态 | 说明 |
|-------------|---------|------|------|
| [mock_user.dart](file:///e:/ai/solotrip/NestWay/lib/mock/mock_user.dart) | users | ✅ 已适配 | id 类型改为 INT |
| [mock_contacts.dart](file:///e:/ai/solotrip/NestWay/lib/mock/mock_contacts.dart) | emergency_contacts | ✅ 已适配 | id/user_id 类型改为 INT，created_at 自动生成 |
| [mock_sos_logs.dart](file:///e:/ai/solotrip/NestWay/lib/mock/mock_sos_logs.dart) | sos_logs | ✅ 已适配 | id/user_id 类型改为 INT，经纬度设为可选 |
| 无 | escort_tasks | ⚠️ 预留 | 暂无对应模拟数据 |

---

**文档结束**