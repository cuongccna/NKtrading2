import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

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

    // Lấy tất cả dữ liệu phân tích của người dùng
    const { data: analyticsData, error } = await supabaseClient
      .from("trade_analytics")
      .select("pnl, day_of_week, mindset_rating")
      .eq("user_id", user.id)
      .not("pnl", "is", null);

    if (error) throw error;

    // --- Phân tích PnL theo ngày trong tuần ---
    const pnlByDay = new Map<number, number>();
    for (let i = 0; i < 7; i++) {
        pnlByDay.set(i, 0); // Khởi tạo PnL cho tất cả các ngày là 0
    }
    analyticsData.forEach(item => {
        const currentPnl = pnlByDay.get(item.day_of_week) || 0;
        pnlByDay.set(item.day_of_week, currentPnl + item.pnl);
    });
    const byDayOfWeek = Array.from(pnlByDay, ([day, pnl]) => ({ day, pnl }));

    // --- Phân tích PnL theo điểm tâm lý ---
    const pnlByMindset = new Map<number, number>();
    analyticsData
        .filter(item => item.mindset_rating != null)
        .forEach(item => {
            const currentPnl = pnlByMindset.get(item.mindset_rating) || 0;
            pnlByMindset.set(item.mindset_rating, currentPnl + item.pnl);
    });
    const byMindset = Array.from(pnlByMindset, ([rating, pnl]) => ({ rating, pnl }));
    
    const result = {
        byDayOfWeek,
        byMindset,
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