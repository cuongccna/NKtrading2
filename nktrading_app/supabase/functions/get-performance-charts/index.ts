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

    // Lấy tham số timeRange từ yêu cầu
    const { timeRange } = await req.json();
    let startDate = new Date(0);
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
    }

    let query = supabaseClient
      .from("trades")
      .select("strategy, entry_price, exit_price, quantity, direction")
      .eq("user_id", user.id)
      .not("exit_price", "is", null)
      .not("strategy", "is", null);

    // Áp dụng bộ lọc ngày nếu không phải 'all'
    if (timeRange !== 'all') {
        query = query.gte('created_at', startDate.toISOString());
    }

    const { data: trades, error } = await query;

    if (error) throw error;

    const performanceByStrategy = new Map<string, number>();

    for (const trade of trades) {
      const pnl = (trade.exit_price - trade.entry_price) * trade.quantity * (trade.direction === "Long" ? 1 : -1);
      const currentPnl = performanceByStrategy.get(trade.strategy) || 0;
      performanceByStrategy.set(trade.strategy, currentPnl + pnl);
    }

    const result = Array.from(performanceByStrategy, ([strategy, pnl]) => ({
      strategy,
      pnl,
    }));
    
    result.sort((a, b) => b.pnl - a.pnl);

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