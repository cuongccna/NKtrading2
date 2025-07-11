// File: supabase/functions/fetch-market-data/index.ts (CẬP NHẬT LỚN)
// Nhiệm vụ: Lấy đồng thời nhiều chỉ số từ Santiment và lưu vào DB.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SANTIMENT_API_URL = "https://api.santiment.net/graphql";

// Hàm để thực hiện một truy vấn GraphQL đến Santiment
async function executeGraphQLQuery(apiKey: string, query: string) {
  const response = await fetch(SANTIMENT_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/graphql",
      "Authorization": `Apikey ${apiKey}`,
    },
    body: query,
  });

  if (!response.ok) {
    throw new Error(`Santiment API Error: ${await response.text()}`);
  }
  return response.json();
}

serve(async (_req) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const apiKey = Deno.env.get("SANTIMENT_API_KEY");
    if (!apiKey) throw new Error("Santiment API key not found in Vault.");

    const asset = "bitcoin"; // Chúng ta sẽ bắt đầu với bitcoin
    const from = "utc_now-2h"; // Lấy dữ liệu trong 2 giờ gần nhất
    const to = "utc_now";
    const interval = "1h"; // Dữ liệu theo giờ

    // Xây dựng một câu lệnh GraphQL phức tạp để lấy tất cả các chỉ số cần thiết
    const query = `query {
      top_holders: getMetric(metric: "top_holders_percent_of_total_supply") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      exchange_inflow: getMetric(metric: "exchange_inflow") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      exchange_outflow: getMetric(metric: "exchange_outflow") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      active_addresses_24h: getMetric(metric: "active_addresses_24h") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      token_age_consumed: getMetric(metric: "token_age_consumed") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      velocity: getMetric(metric: "velocity") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      age_destroyed: getMetric(metric: "age_destroyed") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      social_volume: getMetric(metric: "social_volume_total") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      sentiment_balance: getMetric(metric: "sentiment_balance_total") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
      social_dominance: getMetric(metric: "social_dominance_total") {
        latest: timeseriesData(slug: "${asset}", from: "${from}", to: "${to}", interval: "${interval}", limit: 1) { value }
      }
    }`;

    const data = await executeGraphQLQuery(apiKey, query);

    // Lấy giá trị từ kết quả trả về, nếu không có thì mặc định là null
    const getValue = (metric: string) => data?.data?.[metric]?.latest?.[0]?.value ?? null;

    const snapshotPayload = {
      timestamp: new Date().toISOString(),
      asset: asset,
      top_holders_percent_of_total_supply: getValue('top_holders'),
      exchange_inflow: getValue('exchange_inflow'),
      exchange_outflow: getValue('exchange_outflow'),
      active_addresses_24h: getValue('active_addresses_24h'),
      token_age_consumed: getValue('token_age_consumed'),
      velocity: getValue('velocity'),
      age_destroyed: getValue('age_destroyed'),
      social_volume: getValue('social_volume'),
      sentiment_balance: getValue('sentiment_balance'),
      social_dominance: getValue('social_dominance'),
    };

    // Dùng upsert để thêm mới hoặc cập nhật bản ghi gần nhất
    const { error: insertError } = await supabaseAdmin
      .from("market_data_snapshots")
      .upsert(snapshotPayload, { onConflict: 'timestamp, asset' });

    if (insertError) throw insertError;

    return new Response(
      JSON.stringify({ message: `Successfully synced market data for ${asset}.` }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
