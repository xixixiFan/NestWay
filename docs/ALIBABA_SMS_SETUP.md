# 阿里云短信服务接入指南

## 概述

NestWay 使用阿里云短信服务实现两类短信发送：
- **登录验证码** — Supabase Auth OTP 短信验证（通过 Auth Hook）
- **SOS 求助短信** — 获取实时位置后群发给所有紧急联系人

短信统一通过 Supabase Edge Function 发送，**阿里云 AccessKey 仅存储在服务端**，不会泄露到 App。

## 架构

```
┌──────────────────────────┐
│ Flutter App              │
│                          │
│ 登录验证码:               │
│  signInWithOtp()  ────► Supabase Auth ──► Auth Hook ──► send-sms-alicloud
│  verifyOTP()      ◄──── (自动处理)                         │
│                          │                                │
│ SOS求助短信:             │                                ▼
│  SosService.sendSosSms()──► POST /functions/v1/send-sos-sms
│                          │       │
└──────────────────────────┘       ▼
                          ┌──────────────────┐
                          │ 阿里云短信 API    │
                          │ dysmsapi.aliyuncs.com
                          │ SendSms           │
                          └──────────────────┘
```

## 前置条件

### 1. 阿里云短信服务

1. 开通 [阿里云短信服务](https://www.aliyun.com/product/sms)
2. 创建 AccessKey（建议使用 RAM 子账号，仅授权 `dysmsapi:SendSms`）
3. 申请短信签名（如 "栖途"，需审核）
4. 申请短信模板（见下方）

### 2. 短信模板

#### 登录验证码模板

在阿里云短信控制台创建模板：

```
模板类型: 验证码
模板内容: 您的验证码是${code}，请在5分钟内完成验证。
```

获取模板CODE（如 `SMS_123456789`）。

#### SOS求助短信模板

```
模板类型: 短信通知
模板内容: ${name}向你发送了TA的实时位置，TA可能需要你的帮助！请及时与TA联系并关注TA的动态行踪。当前位置：${location}(你是TA的紧急联系人，因此收到了此信息)
```

获取模板CODE（如 `SMS_987654321`）。

**注意：** 阿里云短信模板不支持在变量中包含坐标信息，因此 `${location}` 应包含完整的地址描述。如需包含坐标，可以将坐标信息合并到 `location` 参数中。

### 3. Supabase CLI

```bash
npm install -g supabase
```

## 部署步骤

### 1. 登录并链接项目

```bash
supabase login
supabase link --project-ref fbnctnhjcjkbmmvcuqxh
```

### 2. 设置环境变量（Secrets）

```bash
# 阿里云 AccessKey
supabase secrets set ALIBABA_ACCESS_KEY_ID=LTAI5txxxxxxxx
supabase secrets set ALIBABA_ACCESS_KEY_SECRET=xxxxxxxxxxxxxxxx

# 短信签名
supabase secrets set ALIBABA_SMS_SIGN_NAME=栖途

# 模板CODE
supabase secrets set ALIBABA_SMS_TEMPLATE_CODE=SMS_123456789
supabase secrets set ALIBABA_SOS_TEMPLATE_CODE=SMS_987654321

# Edge Function 访问密钥（与 Flutter 端 _edgeFunctionSecret 保持一致）
supabase secrets set FUNCTION_SECRET=nestway-sos-sms-2026
```

### 3. 部署 Edge Functions

```bash
supabase functions deploy send-sms-alicloud
supabase functions deploy send-sos-sms
```

### 4. 配置 Supabase Auth Hook（仅登录验证码需要）

在 [Supabase Dashboard](https://supabase.com/dashboard/project/fbnctnhjcjkbmmvcuqxh)：
- 进入 **Authentication** → **Hooks**
- 创建 **Send SMS** Hook：
  - **URL**: `https://fbnctnhjcjkbmmvcuqxh.supabase.co/functions/v1/send-sms-alicloud`
  - **HTTP Headers**: `Authorization: Bearer nestway-sos-sms-2026`

## 验证

### 登录验证码

1. 打开 App → 登录页
2. 输入手机号 → 点击"获取验证码"
3. 手机收到短信，输入验证码完成登录
4. 在 Supabase Dashboard → Edge Functions → send-sms-alicloud → Logs 查看日志

### SOS 求助短信

1. 打开 App → 登录 → SOS 页面
2. 在"紧急联系人"中添加至少一个联系人
3. 点击"发送求助短信"
4. 确认 App 获取到位置后，短信自动发送
5. 联系人的手机收到求助短信，内容格式如下：
   ```
   [用户昵称]向你发送了TA的实时位置，TA可能需要你的帮助！
   请及时与TA联系并关注TA的动态行踪。
   当前位置：北京市东城区天安门广场（39.908823,116.397470）
   (你是TA的紧急联系人，因此收到了此信息)
   ```
6. 在 Supabase Dashboard → Edge Functions → send-sos-sms → Logs 查看日志

## 故障排查

| 问题 | 可能原因 | 解决方式 |
|------|---------|---------|
| 短信未收到 | 签名/模板未审核通过 | 检查阿里云控制台审核状态 |
| Edge Function 返回 401 | FUNCTION_SECRET 不匹配 | 检查 supabase secrets 和 Flutter 端常量 |
| 获取位置失败 | 定位权限未授权 | 检查系统设置中的定位权限 |
| 联系人列表为空 | 未在 Supabase 中配置数据 | 在 App 中添加紧急联系人 |
| 阿里云返回 isv.BUSINESS_LIMIT_CONTROL | 触发频率限制 | 检查阿里云短信发送频率限制 |

## 环境变量参考

| 变量 | 用途 | Edge Function |
|------|------|--------------|
| `ALIBABA_ACCESS_KEY_ID` | 阿里云 AccessKey ID | 两个共用 |
| `ALIBABA_ACCESS_KEY_SECRET` | 阿里云 AccessKey Secret | 两个共用 |
| `ALIBABA_SMS_SIGN_NAME` | 短信签名 | 两个共用 |
| `ALIBABA_SMS_TEMPLATE_CODE` | 登录验证码模板CODE | send-sms-alicloud |
| `ALIBABA_SOS_TEMPLATE_CODE` | SOS求助模板CODE | send-sos-sms |
| `FUNCTION_SECRET` | Edge Function 访问密钥 | 两个共用 |
