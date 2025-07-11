import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

async function getAssetSlug(supabase: SupabaseClient, userSymbol: string): Promise<string | null> {
    let { data: dictEntry, error } = await supabase
        .from('symbol_dictionary')
        .select('santiment_slug')
        .eq('user_symbol', userSymbol)
        .limit(1)
        .single();

    if (!dictEntry) {
        const baseSymbol = userSymbol.split('/')[0].toUpperCase();
        const { data: baseEntry } = await supabase
            .from('symbol_dictionary')
            .select('santiment_slug')
            .ilike('user_symbol', `${baseSymbol}/%`)
            .limit(1)
            .single();
        dictEntry = baseEntry;
    }

    if (error && error.code !== 'PGRST116') {
        console.error("Error fetching from dictionary:", error);
        return null;
    }
    
    return dictEntry?.santiment_slug ?? null;
}

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

    const { data: tradeData, error: tradeError } = await supabase
      .from("trades")
      .select("created_at, symbol")
      .eq("id", trade_id)
      .single();

    if (tradeError) throw tradeError;

    const asset = await getAssetSlug(supabase, tradeData.symbol);
    if (!asset) {
      return new Response(JSON.stringify({ marketContext: null, message: `Asset mapping for ${tradeData.symbol} not found.` }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const tradeDate = tradeData.created_at.split('T')[0];

    // Lấy đồng thời dữ liệu từ cả hai bảng
    const [santimentResult, duneResult] = await Promise.all([
      // Lấy dữ liệu Santiment gần nhất
      supabase
        .from("market_data_snapshots")
        .select("*")
        .eq("asset", asset)
        .lte("timestamp", tradeData.created_at)
        .order("timestamp", { ascending: false })
        .limit(1)
        .single(),
      // *** FIX: Lấy dữ liệu Dune của 7 ngày gần nhất TÍNH TỪ NGÀY GIAO DỊCH ***
      supabase
        .from("dune_whale_data")
        .select("*")
        .lte("date", tradeDate) // Lấy các ngày nhỏ hơn hoặc bằng ngày giao dịch
        .order("date", { ascending: false }) // Sắp xếp để lấy 7 ngày gần nhất
        .limit(7)
    ]);

    const marketContext = {
      santiment: santimentResult.data,
      dune: duneResult.data,
    };

    return new Response(JSON.stringify({ marketContext }), {
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