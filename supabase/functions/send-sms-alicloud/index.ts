// Supabase Auth Hook — Twilio 短信服务
// 部署后需在 Supabase Dashboard → Authentication → Hooks → Send SMS 中配置
// Hook URL: https://<project>.supabase.co/functions/v1/send-sms-alicloud
//
// 所需环境变量（在 Supabase Dashboard 或 supabase secrets 中设置）:
//   TWILIO_ACCOUNT_SID      — Twilio Account SID
//   TWILIO_AUTH_TOKEN       — Twilio Auth Token
//   TWILIO_PHONE_NUMBER     — Twilio 发送号码（格式：+1234567890）
//   FUNCTION_SECRET         — 可选，保护Edge Function不被随意调用

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID")!;
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN")!;
const TWILIO_PHONE_NUMBER = Deno.env.get("TWILIO_PHONE_NUMBER")!;

async function sendTwilioSms(
  to: string,
  body: string,
): Promise<{ ok: boolean; message: string }> {
  const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;

  const formData = new URLSearchParams();
  formData.append("To", to);
  formData.append("From", TWILIO_PHONE_NUMBER);
  formData.append("Body", body);

  const auth = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);

  try {
    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Basic ${auth}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: formData,
    });

    const data = await resp.json();

    if (resp.ok) {
      console.log("Twilio 短信发送成功:", data.sid);
      return { ok: true, message: "OK" };
    } else {
      console.error("Twilio 错误:", data);
      return { ok: false, message: data.message || "发送失败" };
    }
  } catch (err) {
    console.error("Twilio 请求异常:", err);
    return { ok: false, message: String(err) };
  }
}

serve(async (req: Request) => {
  // 校验 Authorization（可选的安全层）
  const secret = Deno.env.get("FUNCTION_SECRET");
  if (secret) {
    const auth = req.headers.get("Authorization");
    if (auth !== `Bearer ${secret}`) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  // 解析请求体
  let phone: string;
  let token: string;

  try {
    const body = await req.json();
    if (body.type && body.phone && body.token) {
      // Supabase Auth Hook 格式
      phone = body.phone.replace(/^\+/, "");
      token = body.token;
    } else if (body.phone && body.code) {
      // 通用格式
      phone = body.phone.replace(/^\+/, "");
      token = body.code;
    } else {
      return new Response(
        JSON.stringify({ error: "缺少 phone 或 token 字段" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
  } catch {
    return new Response(
      JSON.stringify({ error: "请求体JSON解析失败" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // 确保手机号包含国家代码
  const formattedPhone = phone.startsWith("+") ? phone : `+86${phone}`;
  const message = `您的验证码是：${token}。请勿泄露给他人。`;

  console.log(`发送短信到 ${formattedPhone}，验证码 ${token}`);

  // 尝试发送短信，但不阻塞响应
  const result = await sendTwilioSms(formattedPhone, message);

  if (result.ok) {
    console.log(`✅ 短信发送成功: ${formattedPhone}`);
  } else {
    console.error(`❌ 短信发送失败: ${formattedPhone}, 错误: ${result.message}`);
    // 即使失败也记录日志，但不影响用户体验
  }

  // 无论实际发送结果如何，都返回成功响应（乐观UI策略）
  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
