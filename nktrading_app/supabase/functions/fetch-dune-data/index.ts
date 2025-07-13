// File: supabase/functions/fetch-dune-data/index.ts (MỚI)
// Nhiệm vụ: Tự động chạy định kỳ để lấy dữ liệu từ Dune và lưu vào DB.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const DUNE_API_URL = "https://api.dune.com/api/v1";
const QUERY_ID = 5455459; // ID của query bạn đã cung cấp

// Hàm sleep để chờ giữa các lần kiểm tra
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

serve(async (_req) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const apiKey = Deno.env.get("DUNE_API_KEY");
    if (!apiKey) throw new Error("Dune API key not found in Vault.");

    // --- Bước 1: Gửi yêu cầu thực thi Query và lấy execution_id ---
    const executeResponse = await fetch(`${DUNE_API_URL}/query/${QUERY_ID}/execute`, {
      method: "POST",
      headers: { "X-DUNE-API-KEY": apiKey },
      body: JSON.stringify({
        performance: "large", // Sử dụng warehouse lớn hơn để query chạy nhanh hơn
      }),
    });

    if (!executeResponse.ok) {
      throw new Error(`Failed to start Dune query execution: ${await executeResponse.text()}`);
    }
    const { execution_id } = await executeResponse.json();

    // --- Bước 2: Dùng vòng lặp để kiểm tra trạng thái thực thi (Polling) ---
    let executionStatus;
    let attempts = 0;
    const maxAttempts = 30; // Tăng số lần thử lên (30 * 10s = 5 phút)

    while (attempts < maxAttempts) {
      const statusResponse = await fetch(`${DUNE_API_URL}/execution/${execution_id}/status`, {
        headers: { "X-DUNE-API-KEY": apiKey },
      });
      if (!statusResponse.ok) throw new Error("Failed to get execution status.");
      
      executionStatus = await statusResponse.json();

      if (executionStatus.state === "QUERY_STATE_COMPLETED") {
        break; // Thoát khỏi vòng lặp khi đã hoàn thành
      }
      if (executionStatus.state === "QUERY_STATE_FAILED") {
        throw new Error(`Dune query execution failed: ${executionStatus.error?.message}`);
      }
      
      attempts++;
      await sleep(10000); // Chờ 10 giây trước khi kiểm tra lại
    }

    if (executionStatus?.state !== "QUERY_STATE_COMPLETED") {
        throw new Error("Dune query timed out after several attempts.");
    }

    // --- Bước 3: Lấy kết quả khi đã hoàn thành ---
    const resultsResponse = await fetch(`${DUNE_API_URL}/execution/${execution_id}/results`, {
      headers: { "X-DUNE-API-KEY": apiKey },
    });
    if (!resultsResponse.ok) throw new Error("Failed to fetch query results.");
    
    const resultsData = await resultsResponse.json();
    const rows = resultsData.result.rows;

    if (!rows || rows.length === 0) {
      throw new Error("No data received from Dune.");
    }

    // --- Bước 4: Chuẩn bị và lưu dữ liệu vào Supabase ---
    const dataToUpsert = rows.map((row: any) => ({
      date: new Date(row.date).toISOString().split('T')[0], // Lấy YYYY-MM-DD
      whale_to_exchange: row.whale_to_exchange,
      exchange_to_whale: row.exchange_to_whale,
      net_whale_selling: row.net_whale_selling,
      whale_exchange_tx_count: row.whale_exchange_tx_count,
      market_sentiment: row.market_sentiment,
      last_updated: new Date().toISOString(),
    }));

    // Dùng upsert để thêm mới hoặc cập nhật nếu ngày đã tồn tại
    const { error: upsertError } = await supabaseAdmin
      .from("dune_whale_data")
      .upsert(dataToUpsert, { onConflict: 'date' });

    if (upsertError) throw upsertError;

    return new Response(
      JSON.stringify({ message: `Successfully synced ${dataToUpsert.length} data points from Dune.` }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
