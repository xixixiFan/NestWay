-- ==============================================
-- 栖途 NestWay - 数据库初始化脚本
-- 版本：v1.1（适配模拟数据）
-- 项目：fbnctnhjcjkbmmvcuqxh
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
