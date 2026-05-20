# SOS短信内容更新指南

## 📝 更新内容

短信内容已从：
```
【NestWay】紧急求助！[用户]发起了SOS求助，您是TA的紧急联系人。
当前位置：[地址]（[坐标]）。请立即确认TA的安全！
```

更新为：
```
[用户昵称]向你发送了TA的实时位置，TA可能需要你的帮助！
请及时与TA联系并关注TA的动态行踪。
当前位置：[地址]（[坐标]）
(你是TA的紧急联系人，因此收到了此信息)
```

## 🔧 需要执行的步骤

### 1️⃣ 更新阿里云短信模板

登录 [阿里云短信控制台](https://dysms.console.aliyun.com/)：

1. 进入 **国内消息** → **模板管理**
2. 找到现有的SOS短信模板，或创建新模板
3. 填写以下内容：

```
模板类型: 短信通知
模板名称: NestWay SOS求助短信
模板内容: ${name}向你发送了TA的实时位置，TA可能需要你的帮助！请及时与TA联系并关注TA的动态行踪。当前位置：${location}(你是TA的紧急联系人，因此收到了此信息)
```

4. 提交审核（通常1-2小时内审核完成）
5. 审核通过后，记录模板CODE（如 `SMS_123456789`）

### 2️⃣ 更新Supabase环境变量

如果模板CODE发生变化，需要更新：

```bash
# 登录Supabase
supabase login

# 链接项目
supabase link --project-ref fbnctnhjcjkbmmvcuqxh

# 更新模板CODE（使用新的模板CODE）
supabase secrets set ALIBABA_SOS_TEMPLATE_CODE=SMS_新的模板CODE
```

### 3️⃣ 重新部署Edge Function

```bash
# 部署更新后的Edge Function
supabase functions deploy send-sos-sms
```

### 4️⃣ 验证更新

1. 打开App，登录账号
2. 进入 **SOS页面** → 点击 **"共享位置给联系人"**
3. 查看短信预览，确认内容格式正确
4. 点击 **"发送求助短信"**
5. 检查联系人手机，确认收到的短信内容符合新格式

## 📊 代码变更说明

### Flutter端变更

1. **lib/pages/sos/send_sos_message_page.dart**
   - 更新 `_generateMessage()` 方法，使用新的短信文案

2. **lib/services/sos_service.dart**
   - 更新 `sendSosSms()` 方法，将坐标合并到location参数中
   - `coords` 参数改为可选参数

### 后端变更

1. **supabase/functions/send-sos-sms/index.ts**
   - 移除独立的 `coords` 参数
   - 将坐标信息合并到 `location` 参数中传递给阿里云

### 文档变更

1. **docs/ALIBABA_SMS_SETUP.md**
   - 更新短信模板说明
   - 更新验证示例

## 🎯 短信内容示例

**实际发送效果：**

```
张小美向你发送了TA的实时位置，TA可能需要你的帮助！请及时与TA联系并关注TA的动态行踪。当前位置：北京市东城区天安门广场（39.908823,116.397470）(你是TA的紧急联系人，因此收到了此信息)
```

**动态参数：**
- `张小美` - 从数据库获取的用户昵称
- `北京市东城区天安门广场` - 实时获取的地址
- `39.908823,116.397470` - 实时获取的GPS坐标

## ⚠️ 注意事项

1. **阿里云模板审核**
   - 短信模板需要审核通过后才能使用
   - 审核时间通常为1-2小时，工作日更快
   - 如果审核不通过，根据反馈修改后重新提交

2. **字符限制**
   - 阿里云短信单条最多70个字符（含变量）
   - 当前模板约60字符，加上动态内容可能超过70字
   - 如果超过，会按多条计费

3. **变量说明**
   - `${name}` - 用户昵称（建议不超过10个字符）
   - `${location}` - 地址+坐标（可能较长）
   - 如果地址过长，可能导致短信被截断

4. **测试建议**
   - 先用自己的手机号测试
   - 确认短信内容完整、格式正确
   - 检查坐标信息是否准确

## 🔄 回滚方案

如果需要回滚到旧版本：

```bash
# 1. 恢复旧的阿里云模板
# 2. 在Supabase中恢复旧的模板CODE
supabase secrets set ALIBABA_SOS_TEMPLATE_CODE=旧的模板CODE

# 3. 回滚代码（使用git）
git checkout HEAD~1 -- lib/pages/sos/send_sos_message_page.dart
git checkout HEAD~1 -- lib/services/sos_service.dart
git checkout HEAD~1 -- supabase/functions/send-sos-sms/index.ts

# 4. 重新部署
supabase functions deploy send-sos-sms
```

## ✅ 完成检查清单

- [ ] 阿里云短信模板已创建并审核通过
- [ ] Supabase环境变量已更新（如需要）
- [ ] Edge Function已重新部署
- [ ] Flutter代码已更新
- [ ] 已在真机上测试短信发送
- [ ] 确认短信内容格式正确
- [ ] 确认位置信息准确显示

---

**更新日期：** 2026-05-20  
**版本：** v2.0
