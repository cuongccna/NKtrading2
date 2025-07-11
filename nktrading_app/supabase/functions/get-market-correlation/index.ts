// File: supabase/functions/get-market-correlation/index.ts (CẬP NHẬT LỚN)
// Nhiệm vụ: Lấy một bộ dữ liệu thị trường đầy đủ tương ứng với thời điểm giao dịch.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

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

    const { trade_id } = await req.json();
    if (!trade_id) throw new Error("Missing trade_id");

    // 1. Lấy thông tin thời gian và tài sản của giao dịch
    const { data: tradeData, error: tradeError } = await supabase
      .from("trades")
      .select("created_at, symbol")
      .eq("id", trade_id)
      .single();

    if (tradeError) throw tradeError;

    const tradeTimestamp = new Date(tradeData.created_at);
    // Chuyển đổi symbol (vd: BTC/USDT -> bitcoin)
    // Lưu ý: Cần một cơ chế mapping tốt hơn trong tương lai
    const asset = tradeData.symbol.split('/')[0].toLowerCase(); 

    // 2. Tìm bản ghi dữ liệu thị trường gần nhất với thời điểm giao dịch
    // Chúng ta tìm bản ghi có timestamp nhỏ hơn hoặc bằng và gần nhất
    const { data: marketData, error: marketError } = await supabase
      .from("market_data_snapshots")
      .select("*") // Lấy tất cả các cột
      .eq("asset", asset)
      .lte("timestamp", tradeData.created_at) // Lấy snapshot trước hoặc tại thời điểm trade
      .order("timestamp", { ascending: false }) // Sắp xếp để lấy cái gần nhất
      .limit(1)
      .single(); // Chỉ lấy một bản ghi

    if (marketError) {
        // Nếu không tìm thấy bản ghi nào, không phải là lỗi nghiêm trọng
        if (marketError.code === 'PGRST116') {
             return new Response(JSON.stringify({ marketContext: null, message: "No market data snapshot found for this time." }), {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
                status: 200,
            });
        }
        throw marketError;
    }

    return new Response(JSON.stringify({ marketContext: marketData }), {
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
