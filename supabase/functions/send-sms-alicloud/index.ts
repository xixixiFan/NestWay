// Supabase Auth Hook — 阿里云短信服务
// 部署后需在 Supabase Dashboard → Authentication → Hooks → Send SMS 中配置
// Hook URL: https://<project>.supabase.co/functions/v1/send-sms-alicloud
//
// 所需环境变量（在 Supabase Dashboard 或 supabase secrets 中设置）:
//   ALIBABA_ACCESS_KEY_ID
//   ALIBABA_ACCESS_KEY_SECRET
//   ALIBABA_SMS_SIGN_NAME      — 短信签名（需在阿里云短信控制台已审核通过）
//   ALIBABA_SMS_TEMPLATE_CODE  — 短信模板CODE，模板需包含 ${code} 变量
//   FUNCTION_SECRET            — 可选，保护Edge Function不被随意调用

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ACCESS_KEY_ID = Deno.env.get("ALIBABA_ACCESS_KEY_ID")!;
const ACCESS_KEY_SECRET = Deno.env.get("ALIBABA_ACCESS_KEY_SECRET")!;
const SMS_SIGN_NAME = Deno.env.get("ALIBABA_SMS_SIGN_NAME")!;
const SMS_TEMPLATE_CODE = Deno.env.get("ALIBABA_SMS_TEMPLATE_CODE")!;

function percentEncode(s: string): string {
  return encodeURIComponent(s)
    .replace(/!/g, "%21")
    .replace(/'/g, "%27")
    .replace(/\(/g, "%28")
    .replace(/\)/g, "%29")
    .replace(/\*/g, "%2A")
    .replace(/\+/g, "%20")
    .replace(/%7E/g, "~");
}

async function hmacSha1(key: string, data: string): Promise<ArrayBuffer> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(data));
}

async function buildAliyunParams(
  phone: string,
  code: string,
): Promise<URLSearchParams> {
  const nonce = crypto.randomUUID().replace(/-/g, "");
  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

  const params: Record<string, string> = {
    AccessKeyId: ACCESS_KEY_ID,
    Action: "SendSms",
    Format: "JSON",
    PhoneNumbers: phone,
    SignName: SMS_SIGN_NAME,
    SignatureMethod: "HMAC-SHA1",
    SignatureNonce: nonce,
    SignatureVersion: "1.0",
    TemplateCode: SMS_TEMPLATE_CODE,
    TemplateParam: JSON.stringify({ code }),
    Timestamp: timestamp,
    Version: "2017-05-25",
  };

  const sortedKeys = Object.keys(params).sort();
  const canonicalQuery = sortedKeys
    .map((k) => `${percentEncode(k)}=${percentEncode(params[k])}`)
    .join("&");

  const stringToSign =
    `POST&${percentEncode("/")}&${percentEncode(canonicalQuery)}`;
  const sig = await hmacSha1(ACCESS_KEY_SECRET + "&", stringToSign);
  const signature = btoa(String.fromCharCode(...new Uint8Array(sig)));

  const result = new URLSearchParams();
  result.set("Signature", signature);
  for (const [k, v] of Object.entries(params)) {
    result.set(k, v);
  }
  return result;
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

  console.log(`发送短信到 ${phone}，验证码 ${token}`);

  try {
    const params = await buildAliyunParams(phone, token);
    const resp = await fetch("https://dysmsapi.aliyuncs.com/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params,
    });
    const data = await resp.json();

    console.log("阿里云短信响应:", JSON.stringify(data));

    if (data.Code === "OK") {
      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ error: data.Message || "短信发送失败", code: data.Code }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("短信发送异常:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
