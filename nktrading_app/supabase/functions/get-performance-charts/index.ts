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

    const { data: trades, error } = await supabaseClient
      .from("trades")
      .select("strategy, entry_price, exit_price, quantity, direction")
      .eq("user_id", user.id)
      .not("exit_price", "is", null)
      .not("strategy", "is", null);

    if (error) throw error;

    // Sử dụng một Map để nhóm PnL theo chiến lược
    const performanceByStrategy = new Map<string, number>();

    for (const trade of trades) {
      const pnl = (trade.exit_price - trade.entry_price) * trade.quantity * (trade.direction === "Long" ? 1 : -1);
      const currentPnl = performanceByStrategy.get(trade.strategy) || 0;
      performanceByStrategy.set(trade.strategy, currentPnl + pnl);
    }

    // Chuyển đổi Map thành mảng để trả về
    const result = Array.from(performanceByStrategy, ([strategy, pnl]) => ({
      strategy,
      pnl,
    }));
    
    // Sắp xếp kết quả để các chiến lược có PnL cao nhất hiển thị trước
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