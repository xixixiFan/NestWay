// Supabase Edge Function — SOS 求助短信群发（阿里云）
// 部署: supabase functions deploy send-sos-sms
// 环境变量:
//   ALIBABA_ACCESS_KEY_ID
//   ALIBABA_ACCESS_KEY_SECRET
//   ALIBABA_SMS_SIGN_NAME         — 短信签名（已审核通过）
//   ALIBABA_SOS_TEMPLATE_CODE     — SOS 短信模板CODE
//   FUNCTION_SECRET               — Edge Function 访问密钥

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ACCESS_KEY_ID = Deno.env.get("ALIBABA_ACCESS_KEY_ID")!;
const ACCESS_KEY_SECRET = Deno.env.get("ALIBABA_ACCESS_KEY_SECRET")!;
const SMS_SIGN_NAME = Deno.env.get("ALIBABA_SMS_SIGN_NAME")!;
const SOS_TEMPLATE_CODE = Deno.env.get("ALIBABA_SOS_TEMPLATE_CODE")!;

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
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(key),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    new TextEncoder().encode(data),
  );
}

async function callSendSms(params: {
  phoneNumbers: string;
  templateParam: object;
}): Promise<{ ok: boolean; message: string }> {
  const nonce = crypto.randomUUID().replace(/-/g, "");
  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

  const queryParams: Record<string, string> = {
    AccessKeyId: ACCESS_KEY_ID,
    Action: "SendSms",
    Format: "JSON",
    PhoneNumbers: params.phoneNumbers,
    SignName: SMS_SIGN_NAME,
    SignatureMethod: "HMAC-SHA1",
    SignatureNonce: nonce,
    SignatureVersion: "1.0",
    TemplateCode: SOS_TEMPLATE_CODE,
    TemplateParam: JSON.stringify(params.templateParam),
    Timestamp: timestamp,
    Version: "2017-05-25",
  };

  const sortedKeys = Object.keys(queryParams).sort();
  const canonicalQuery = sortedKeys
    .map((k) => `${percentEncode(k)}=${percentEncode(queryParams[k])}`)
    .join("&");

  const stringToSign =
    `POST&${percentEncode("/")}&${percentEncode(canonicalQuery)}`;
  const sig = await hmacSha1(ACCESS_KEY_SECRET + "&", stringToSign);
  const signature = btoa(String.fromCharCode(...new Uint8Array(sig)));

  const body = new URLSearchParams();
  body.set("Signature", signature);
  for (const [k, v] of Object.entries(queryParams)) {
    body.set(k, v);
  }

  const resp = await fetch("https://dysmsapi.aliyuncs.com/", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  const data = await resp.json();

  console.log("阿里云响应:", JSON.stringify(data));

  if (data.Code === "OK") {
    return { ok: true, message: "OK" };
  }
  return { ok: false, message: data.Message || data.Code || "Unknown error" };
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
  let coords: string;

  try {
    const body = await req.json();
    phones = body.phones;
    name = body.name;
    location = body.location;
    coords = body.coords;

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

  // 过滤无效手机号
  const validPhones = phones
    .map((p) => p.replace(/\s/g, "").replace(/^\+86/, ""))
    .filter((p) => /^1\d{10}$/.test(p));

  if (validPhones.length === 0) {
    return new Response(
      JSON.stringify({ error: "没有有效的手机号", phones }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const phoneNumbers = validPhones.join(",");

  console.log(`发送SOS短信到: ${phoneNumbers}`);
  console.log(`  用户: ${name}, 位置: ${location}, 坐标: ${coords}`);

  // 阿里云 SendSms 支持最多1000个逗号分隔的号码
  const result = await callSendSms({
    phoneNumbers,
    templateParam: { name, location, coords: coords || "" },
  });

  if (result.ok) {
    return new Response(
      JSON.stringify({ success: true, sentTo: validPhones.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ error: result.message, sentTo: 0 }),
    { status: 500, headers: { "Content-Type": "application/json" } },
  );
});
