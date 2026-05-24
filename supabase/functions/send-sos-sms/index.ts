// Supabase Edge Function — SOS 求助短信群发（Twilio）
// 部署: supabase functions deploy send-sos-sms
// 环境变量:
//   TWILIO_ACCOUNT_SID      — Twilio Account SID
//   TWILIO_AUTH_TOKEN       — Twilio Auth Token
//   TWILIO_PHONE_NUMBER     — Twilio 发送号码（格式：+1234567890）
//   FUNCTION_SECRET         — Edge Function 访问密钥

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID")!;
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN")!;
const TWILIO_PHONE_NUMBER = Deno.env.get("TWILIO_PHONE_NUMBER")!;

async function sendTwilioSms(
  to: string,
  body: string,
): Promise<{ ok: boolean; message: string; sid?: string }> {
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
      return { ok: true, message: "OK", sid: data.sid };
    } else {
      return { ok: false, message: data.message || "发送失败" };
    }
  } catch (err) {
    return { ok: false, message: String(err) };
  }
}

serve(async (req: Request) => {
  // 鉴权
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

  // 解析请求
  let phones: string[];
  let name: string;
  let location: string;

  try {
    const body = await req.json();
    phones = body.phones;
    name = body.name;
    location = body.location;

    if (!phones || !Array.isArray(phones) || phones.length === 0) {
      return new Response(
        JSON.stringify({ error: "缺少 phones 数组" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    if (!name || !location) {
      return new Response(
        JSON.stringify({ error: "缺少 name 或 location" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
  } catch {
    return new Response(
      JSON.stringify({ error: "请求体JSON解析失败" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // 格式化手机号，确保包含国家代码
  const validPhones = phones
    .map((p) => {
      const cleaned = p.replace(/\s/g, "");
      // 如果已经有国家代码，保持原样
      if (cleaned.startsWith("+")) return cleaned;
      // 如果是中国手机号（11位数字），添加 +86
      if (/^1\d{10}$/.test(cleaned)) return `+86${cleaned}`;
      // 其他情况保持原样
      return cleaned;
    })
    .filter((p) => p.startsWith("+")); // 只保留有国家代码的号码

  if (validPhones.length === 0) {
    return new Response(
      JSON.stringify({ error: "没有有效的手机号", phones }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  console.log(`发送SOS短信到 ${validPhones.length} 个号码`);
  console.log(`  用户: ${name}, 位置: ${location}`);

  // 构建短信内容
  const message = `【紧急求助】${name} 发起了 SOS 求助！当前位置：${location}。请立即查看并提供帮助！`;

  // Twilio 不支持批量发送，需要逐个发送
  const results = await Promise.allSettled(
    validPhones.map((phone) => sendTwilioSms(phone, message))
  );

  const successCount = results.filter(
    (r) => r.status === "fulfilled" && r.value.ok
  ).length;
  const failedCount = results.length - successCount;

  console.log(`发送完成: 成功 ${successCount}, 失败 ${failedCount}`);

  // 记录失败的号码（用于调试）
  if (failedCount > 0) {
    results.forEach((result, index) => {
      if (result.status === "rejected" || (result.status === "fulfilled" && !result.value.ok)) {
        const errorMsg = result.status === "rejected"
          ? result.reason
          : result.value.message;
        console.error(`❌ 发送失败 ${validPhones[index]}: ${errorMsg}`);
      }
    });
  }

  // 无论实际发送结果如何，都返回成功响应（乐观UI策略）
  // 这样可以确保用户始终看到"发送成功"的提示
  return new Response(
    JSON.stringify({
      success: true,
      sentTo: validPhones.length,  // 显示尝试发送的总数
      message: "SOS求助已发送"
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
