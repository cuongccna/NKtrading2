// ✅ Đã sửa cú pháp import và bỏ hmac.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { decrypt } from "../_shared/crypto.ts";

const BINANCE_API_URL = "https://api.binance.com";

// ✅ Hàm tạo chữ ký HMAC SHA256 với Web Crypto API
async function createHmacSignature(secret: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signatureBuffer = await crypto.subtle.sign("HMAC", key, enc.encode(message));
  const hashArray = Array.from(new Uint8Array(signatureBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
  return hashHex;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("Unauthorized");

    // Lấy API key của người dùng cho Binance
    const { data: apiKeyData, error: apiKeyError } = await supabase
      .from("user_api_keys")
      .select("api_key_encrypted, api_secret_encrypted")
      .eq("user_id", user.id)
      .eq("exchange", "Binance")
      .limit(1)
      .single();

    if (apiKeyError || !apiKeyData) {
      throw new Error("No Binance API key found for this user.");
    }

    const encryptionKeyString = Deno.env.get("API_ENCRYPTION_KEY");
    if (!encryptionKeyString) throw new Error("Encryption key not found in Vault.");

    const keyData = new TextEncoder().encode(encryptionKeyString);
    const cryptoKey = await crypto.subtle.importKey("raw", keyData, { name: "AES-GCM" }, true, ["encrypt", "decrypt"]);

    const apiKey = await decrypt(apiKeyData.api_key_encrypted, cryptoKey);
    const apiSecret = await decrypt(apiKeyData.api_secret_encrypted, cryptoKey);

    const { data: existingSymbols } = await supabase
      .from("trades")
      .select("symbol")
      .eq("user_id", user.id);

    const symbols = [...new Set(existingSymbols?.map(t => t.symbol) || [])];
    if (symbols.length === 0) {
      return new Response(JSON.stringify({ message: "No symbols to sync." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    let syncedCount = 0;

    for (const symbol of symbols) {
      const timestamp = Date.now();
      const queryString = `symbol=${symbol}&timestamp=${timestamp}`;
      const signature = await createHmacSignature(apiSecret, queryString);

      const url = `${BINANCE_API_URL}/api/v3/myTrades?${queryString}&signature=${signature}`;
      const response = await fetch(url, {
        headers: { "X-MBX-APIKEY": apiKey },
      });

      if (!response.ok) {
        console.error(`Error fetching trades for ${symbol}:`, await response.text());
        continue;
      }

      const trades = await response.json();
      if (!Array.isArray(trades) || trades.length === 0) continue;

      const tradesToInsert = trades.map(trade => ({
        user_id: user.id,
        symbol: trade.symbol,
        exchange_trade_id: trade.id.toString(),
        direction: trade.isBuyer ? "Long" : "Short",
        entry_price: parseFloat(trade.price),
        exit_price: parseFloat(trade.price),
        quantity: parseFloat(trade.qty),
        notes: `Synced from Binance. Commission: ${trade.commission} ${trade.commissionAsset}`,
        created_at: new Date(trade.time).toISOString(),
      }));

      const { error: insertError } = await supabase
        .from("trades")
        .upsert(tradesToInsert, { onConflict: 'exchange_trade_id, user_id' });

      if (insertError) {
        console.error(`Error inserting trades for ${symbol}:`, insertError);
      } else {
        syncedCount += tradesToInsert.length;
      }
    }

    return new Response(JSON.stringify({ message: `Sync completed. ${syncedCount} trades processed.` }), {
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
