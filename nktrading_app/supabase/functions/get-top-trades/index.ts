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

    const { targetCurrency } = await req.json();

    // Lấy tất cả các giao dịch đã đóng của người dùng
    const { data: trades, error } = await supabase
      .from('trades')
      .select('symbol, entry_price, exit_price, quantity, direction')
      .eq('user_id', user.id)
      .not('exit_price', 'is', null);

    if (error) throw error;

      // *** NEW: Lấy tỷ giá hối đoái ***
    let exchangeRate = 1.0;
    if (targetCurrency === 'VND') {
      const { data: rateData } = await supabase.functions.invoke('get-exchange-rate');
      if (rateData?.rate) {
        exchangeRate = rateData.rate;
      }
    }

    // Tính toán PnL cho mỗi giao dịch
    const tradesWithPnl = trades.map(trade => {
        const pnl = (trade.exit_price - trade.entry_price) * trade.quantity * (trade.direction === 'Long' ? 1 : -1);
        const convertedPnl = pnl * exchangeRate;
        return { symbol: trade.symbol, pnl: convertedPnl };
    });

    // Sắp xếp theo PnL
    tradesWithPnl.sort((a, b) => b.pnl - a.pnl);

    // Lấy top 10 lệnh thắng và top 10 lệnh lỗ
    const topWinners = tradesWithPnl.slice(0, 10);
    const topLosers = tradesWithPnl.filter(t => t.pnl < 0).reverse().slice(0, 10);

    return new Response(JSON.stringify({ topWinners, topLosers }), {
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