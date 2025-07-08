// File: supabase/functions/get-exchange-rate/index.ts
// CẬP NHẬT: Sử dụng API của exchangerate.host, không cần API key.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const CACHE_DURATION_HOURS = 6; // Thời gian cache: 6 giờ

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const baseCode = "USD";
    const targetCode = "VND";

    // 1. Kiểm tra cache trước
    const { data: cachedData, error: cacheError } = await supabaseAdmin
      .from("exchange_rate_cache")
      .select("conversion_rate, last_updated")
      .eq("base_code", baseCode)
      .eq("target_code", targetCode)
      .single();

    if (cacheError && cacheError.code !== 'PGRST116') {
      throw cacheError;
    }

    if (cachedData) {
      const lastUpdated = new Date(cachedData.last_updated);
      const now = new Date();
      const hoursDiff = (now.getTime() - lastUpdated.getTime()) / 3600000;

      if (hoursDiff < CACHE_DURATION_HOURS) {
        return new Response(JSON.stringify({ rate: cachedData.conversion_rate }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        });
      }
    }

    // 2. Nếu cache không có hoặc đã cũ, gọi API của CurrencyFreaks
    const apiKey = Deno.env.get("CURRENCYFREAKS_API_KEY");
    if (!apiKey) throw new Error("CurrencyFreaks API key not found in Vault.");

    const apiUrl = `https://api.currencyfreaks.com/v2.0/rates/latest?apikey=${apiKey}&symbols=${targetCode},${baseCode}`;
    const response = await fetch(apiUrl);
    if (!response.ok) throw new Error("Failed to fetch from CurrencyFreaks API.");

    const data = await response.json();
    const newRate = parseFloat(data.rates[targetCode]);

    if (!newRate) throw new Error("Invalid response from CurrencyFreaks API.");

    // 3. Cập nhật cache với dữ liệu mới
    await supabaseAdmin
      .from("exchange_rate_cache")
      .upsert({
        base_code: baseCode,
        target_code: targetCode,
        conversion_rate: newRate,
        last_updated: new Date().toISOString(),
      }, { onConflict: 'base_code, target_code' });

    return new Response(JSON.stringify({ rate: newRate }), {
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