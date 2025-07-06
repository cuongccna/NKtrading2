// File: supabase/functions/get-winning-patterns/index.ts (MỚI)
// Nhiệm vụ: Phân tích dữ liệu để tìm ra các mẫu giao dịch hiệu quả nhất.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Hàm trợ giúp để nhóm và tính toán thống kê
function analyzeGroupBy<T>(
  data: T[],
  keyGetter: (item: T) => string | null,
  pnlGetter: (item: T) => number
) {
  const groupStats = new Map<string, { pnl: number; winCount: number; tradeCount: number }>();

  for (const item of data) {
    const key = keyGetter(item);
    if (key === null || key === undefined) continue;

    const stats = groupStats.get(key) || { pnl: 0, winCount: 0, tradeCount: 0 };
    const pnl = pnlGetter(item);

    stats.pnl += pnl;
    stats.tradeCount += 1;
    if (pnl > 0) {
      stats.winCount += 1;
    }
    groupStats.set(key, stats);
  }

  const result = Array.from(groupStats, ([key, stats]) => ({
    key,
    pnl: stats.pnl,
    tradeCount: stats.tradeCount,
    winrate: stats.tradeCount > 0 ? (stats.winCount / stats.tradeCount) * 100 : 0,
  }));
  
  // Trả về nhóm có PnL cao nhất
  if (result.length === 0) return null;
  return result.reduce((prev, current) => (prev.pnl > current.pnl) ? prev : current);
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

    // Lấy tất cả dữ liệu phân tích của người dùng có PnL
    const { data: analyticsData, error } = await supabaseClient
      .from("trade_analytics")
      .select("pnl, day_of_week, trading_session, strategy")
      .eq("user_id", user.id)
      .not("pnl", "is", null);

    if (error) throw error;
    if (!analyticsData || analyticsData.length === 0) {
      return new Response(JSON.stringify({ message: "Not enough data for analysis." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    
    // --- Bắt đầu phân tích ---
    const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

    const bestStrategy = analyzeGroupBy(analyticsData, (item) => item.strategy, (item) => item.pnl);
    const bestDay = analyzeGroupBy(analyticsData, (item) => days[item.day_of_week], (item) => item.pnl);
    const bestSession = analyzeGroupBy(analyticsData, (item) => item.trading_session, (item) => item.pnl);

    const patterns = {
      bestStrategy,
      bestDay,
      bestSession,
    };

    return new Response(JSON.stringify(patterns), {
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
