// File: supabase/functions/get-psychological-impact/index.ts (MỚI)
// Nhiệm vụ: Phân tích ảnh hưởng của tâm lý đến kết quả giao dịch.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Hàm trợ giúp để nhóm và tính toán thống kê
function analyzePsychology<T>(
  data: T[],
  keyGetter: (item: T) => string | number | null | string[],
  pnlGetter: (item: T) => number
) {
  const groupStats = new Map<string, { pnl: number; tradeCount: number }>();

  for (const item of data) {
    const keys = keyGetter(item);
    if (keys === null || keys === undefined) continue;

    // Xử lý trường hợp key là một mảng (cho emotion_tags)
    const keyArray = Array.isArray(keys) ? keys : [keys.toString()];

    for (const key of keyArray) {
      if (!key) continue;
      const stats = groupStats.get(key) || { pnl: 0, tradeCount: 0 };
      const pnl = pnlGetter(item);

      stats.pnl += pnl;
      stats.tradeCount += 1;
      groupStats.set(key, stats);
    }
  }

  return Array.from(groupStats, ([key, stats]) => ({
    key,
    pnl: stats.pnl,
    averagePnl: stats.tradeCount > 0 ? stats.pnl / stats.tradeCount : 0,
    tradeCount: stats.tradeCount,
  }));
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
      .select("pnl, mindset_rating, emotion_tags")
      .eq("user_id", user.id)
      .not("pnl", "is", null);

    if (error) throw error;
    if (!analyticsData || analyticsData.length === 0) {
      return new Response(JSON.stringify({ message: "Not enough data for analysis." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    
    // --- Bắt đầu phân tích ---
    const byMindset = analyzePsychology(analyticsData, (item) => item.mindset_rating, (item) => item.pnl);
    const byEmotionTag = analyzePsychology(analyticsData, (item) => item.emotion_tags, (item) => item.pnl);

    // Sắp xếp kết quả
    byMindset.sort((a, b) => a.key.localeCompare(b.key));
    byEmotionTag.sort((a, b) => b.pnl - a.pnl);

    const result = {
      byMindset,
      byEmotionTag,
    };

    return new Response(JSON.stringify(result), {
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
