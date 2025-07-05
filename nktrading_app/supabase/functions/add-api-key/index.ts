// File: supabase/functions/add-api-key/index.ts
// Nhiệm vụ: Mã hóa và lưu trữ API key của người dùng một cách an toàn.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// --- Hàm mã hóa ---
async function encrypt(data: string, key: CryptoKey): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12)); // Initialization Vector
  const encodedData = new TextEncoder().encode(data);

  const encryptedData = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: iv },
    key,
    encodedData
  );

  // Kết hợp IV và dữ liệu đã mã hóa để lưu trữ, ngăn cách bởi "."
  const ivString = Array.from(iv).map(b => b.toString(16).padStart(2, '0')).join('');
  const encryptedString = Array.from(new Uint8Array(encryptedData)).map(b => b.toString(16).padStart(2, '0')).join('');
  
  return `${ivString}.${encryptedString}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Unauthorized");

    // Lấy dữ liệu từ request body
    const { exchange, label, apiKey, apiSecret } = await req.json();
    if (!exchange || !apiKey || !apiSecret) {
      throw new Error("Missing required fields: exchange, apiKey, apiSecret");
    }

    // Lấy khóa mã hóa từ Vault
    const encryptionKeyString = Deno.env.get("API_ENCRYPTION_KEY");
    if (!encryptionKeyString) {
      throw new Error("API_ENCRYPTION_KEY not found in Vault.");
    }
    const keyData = new TextEncoder().encode(encryptionKeyString);
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "AES-GCM" },
      true,
      ["encrypt", "decrypt"]
    );

    // Mã hóa API key và secret
    const encryptedApiKey = await encrypt(apiKey, cryptoKey);
    const encryptedApiSecret = await encrypt(apiSecret, cryptoKey);

    // Lưu vào cơ sở dữ liệu
    const { error } = await supabaseClient.from("user_api_keys").insert({
      user_id: user.id,
      exchange: exchange,
      label: label,
      api_key_encrypted: encryptedApiKey,
      api_secret_encrypted: encryptedApiSecret,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ message: "API key saved successfully" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
