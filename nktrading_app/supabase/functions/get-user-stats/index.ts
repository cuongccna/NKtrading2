import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

console.log("get-user-stats function initialized");

// Rate limiting
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 30;
const rateLimitMap = new Map<string, number[]>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const userRequests = rateLimitMap.get(userId) || [];
  const recentRequests = userRequests.filter(time => now - time < RATE_LIMIT_WINDOW);
  
  if (recentRequests.length >= MAX_REQUESTS_PER_WINDOW) {
    return false;
  }
  
  recentRequests.push(now);
  rateLimitMap.set(userId, recentRequests);
  return true;
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
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    // Check rate limit
    if (!checkRateLimit(user.id)) {
      return new Response(JSON.stringify({ 
        error: "Too many requests. Please try again later." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 429,
      });
    }

    // Parse request body
    let timeRange = 'all';
    let targetCurrency = 'USD';
    
    try {
      const body = await req.json();
      timeRange = body.timeRange || 'all';
      targetCurrency = body.targetCurrency || 'USD';
      
      // Validate input
      const validTimeRanges = ['daily', 'weekly', 'monthly', 'yearly', 'all'];
      if (!validTimeRanges.includes(timeRange)) {
        throw new Error("Invalid time range");
      }
      
      const validCurrencies = ['USD', 'VND'];
      if (!validCurrencies.includes(targetCurrency)) {
        throw new Error("Invalid currency");
      }
    } catch (parseError) {
      return new Response(JSON.stringify({ 
        error: "Invalid request parameters" 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // Calculate date range
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

    // Build query with proper error handling
    let query = supabaseClient
      .from("trades")
      .select("entry_price, exit_price, quantity, direction, created_at")
      .eq("user_id", user.id)
      .not("exit_price", "is", null);
      
    if (timeRange !== 'all') {
      query = query.gte('created_at', startDate.toISOString());
    }

    const { data: trades, error } = await query.order("created_at", { ascending: true });

    if (error) {
      console.error("Database query error:", error);
      return new Response(JSON.stringify({ 
        error: "Failed to fetch trading data. Please try again." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    // Get exchange rate if needed
    let exchangeRate = 1.0;
    if (targetCurrency === 'VND') {
      try {
        const { data: rateData, error: rateError } = await supabaseClient.functions.invoke('get-exchange-rate');
        if (rateError) {
          console.error("Exchange rate error:", rateError);
          // Continue with default rate rather than failing
        } else if (rateData?.rate) {
          exchangeRate = rateData.rate;
        }
      } catch (rateError) {
        console.error("Failed to get exchange rate:", rateError);
        // Continue with default rate
      }
    }

    // Calculate statistics with validation
    let totalPnl = 0;
    let totalWins = 0;
    let totalLosses = 0;
    let totalWinAmount = 0;
    let totalLossAmount = 0;
    const equityCurveData = [];
    let cumulativePnl = 0;

    for (const trade of trades || []) {
      try {
        // Validate trade data
        if (!trade.entry_price || !trade.exit_price || !trade.quantity || !trade.direction) {
          console.warn("Invalid trade data:", trade);
          continue;
        }

        const entryPrice = parseFloat(trade.entry_price);
        const exitPrice = parseFloat(trade.exit_price);
        const quantity = parseFloat(trade.quantity);
        
        if (isNaN(entryPrice) || isNaN(exitPrice) || isNaN(quantity)) {
          console.warn("Invalid numeric values in trade:", trade);
          continue;
        }

        const isLong = trade.direction === "Long";
        const pnl = (exitPrice - entryPrice) * quantity * (isLong ? 1 : -1);
        const convertedPnl = pnl * exchangeRate;
        
        totalPnl += convertedPnl;
        if (convertedPnl > 0) {
          totalWins++;
          totalWinAmount += convertedPnl;
        } else if (convertedPnl < 0) {
          totalLosses++;
          totalLossAmount += Math.abs(convertedPnl);
        }
        
        cumulativePnl += convertedPnl;
        equityCurveData.push({
          date: trade.created_at,
          pnl: parseFloat(cumulativePnl.toFixed(2)),
        });
      } catch (tradeError) {
        console.error("Error processing trade:", tradeError);
        continue;
      }
    }

    const totalTrades = trades?.length || 0;
    const winrate = totalTrades > 0 ? (totalWins / totalTrades) * 100 : 0;
    const averageWin = totalWins > 0 ? totalWinAmount / totalWins : 0;
    const averageLoss = totalLosses > 0 ? totalLossAmount / totalLosses : 0;
    const profitFactor = totalLossAmount > 0 ? totalWinAmount / totalLossAmount : 0;

    const stats = {
      totalPnl: parseFloat(totalPnl.toFixed(2)),
      winrate: parseFloat(winrate.toFixed(2)),
      averageWin: parseFloat(averageWin.toFixed(2)),
      averageLoss: parseFloat(averageLoss.toFixed(2)),
      profitFactor: parseFloat(profitFactor.toFixed(2)),
      totalWins,
      totalLosses,
      totalTrades,
      equityCurve: equityCurveData,
      currency: targetCurrency,
      exchangeRate: targetCurrency === 'VND' ? exchangeRate : undefined,
    };

    return new Response(JSON.stringify(stats), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ 
      error: "An unexpected error occurred. Please try again later." 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});