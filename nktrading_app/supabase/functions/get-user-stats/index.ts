// File: supabase/functions/get-user-stats/index.ts
// CẬP NHẬT: Thêm logic lọc theo khoảng thời gian (timeRange)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

console.log("get-user-stats function initialized");

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
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    // *** NEW: Lấy tham số timeRange từ yêu cầu ***
    const { timeRange } = await req.json();
    let startDate = new Date(0); // Mặc định lấy từ đầu
    const now = new Date();

    switch (timeRange) {
      case 'daily':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case 'weekly':
        const dayOfWeek = now.getDay();
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1));
        break;
      case 'monthly':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        break;
      case 'yearly':
        startDate = new Date(now.getFullYear(), 0, 1);
        break;
      // 'all' case sẽ không lọc theo ngày bắt đầu
    }

    let query = supabaseClient
      .from("trades")
      .select("entry_price, exit_price, quantity, direction, created_at")
      .eq("user_id", user.id)
      .not("exit_price", "is", null);
      
    // *** NEW: Áp dụng bộ lọc ngày nếu không phải 'all' ***
    if (timeRange !== 'all') {
        query = query.gte('created_at', startDate.toISOString());
    }

    const { data: trades, error } = await query.order("created_at", { ascending: true });

    if (error) {
      throw error;
    }

    // --- Logic tính toán giữ nguyên ---
    let totalPnl = 0;
    let totalWins = 0;
    let totalLosses = 0;
    let totalWinAmount = 0;
    let totalLossAmount = 0;
    const equityCurveData = [];
    let cumulativePnl = 0;

    for (const trade of trades) {
      const entryPrice = trade.entry_price;
      const exitPrice = trade.exit_price;
      const quantity = trade.quantity;
      const isLong = trade.direction === "Long";
      const pnl = (exitPrice - entryPrice) * quantity * (isLong ? 1 : -1);
      
      totalPnl += pnl;
      if (pnl > 0) {
        totalWins++;
        totalWinAmount += pnl;
      } else if (pnl < 0) {
        totalLosses++;
        totalLossAmount += Math.abs(pnl);
      }
      
      cumulativePnl += pnl;
      equityCurveData.push({
        date: trade.created_at,
        pnl: cumulativePnl,
      });
    }

    const totalTrades = trades.length;
    const winrate = totalTrades > 0 ? (totalWins / totalTrades) * 100 : 0;
    const averageWin = totalWins > 0 ? totalWinAmount / totalWins : 0;
    const averageLoss = totalLosses > 0 ? totalLossAmount / totalLosses : 0;
    const profitFactor = totalLossAmount > 0 ? totalWinAmount / totalLossAmount : 0;

    const stats = {
      totalPnl,
      winrate,
      averageWin,
      averageLoss,
      profitFactor,
      totalWins,
      totalLosses,
      totalTrades,
      equityCurve: equityCurveData,
    };

    return new Response(JSON.stringify(stats), {
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
