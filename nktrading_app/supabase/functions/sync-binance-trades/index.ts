import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { decrypt } from "../_shared/crypto.ts";

const BINANCE_API_URL = "https://api.binance.com";
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

// Rate limiting configuration
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 10;
const rateLimitMap = new Map<string, number[]>();

// Helper function to check rate limit
function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const userRequests = rateLimitMap.get(userId) || [];
  
  // Filter out old requests
  const recentRequests = userRequests.filter(time => now - time < RATE_LIMIT_WINDOW);
  
  if (recentRequests.length >= MAX_REQUESTS_PER_WINDOW) {
    return false;
  }
  
  recentRequests.push(now);
  rateLimitMap.set(userId, recentRequests);
  return true;
}

// Helper function for exponential backoff retry
async function fetchWithRetry(url: string, options: RequestInit, retries = MAX_RETRIES): Promise<Response> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000); // 10 second timeout
    
    const response = await fetch(url, {
      ...options,
      signal: controller.signal
    });
    
    clearTimeout(timeout);
    
    if (!response.ok && retries > 0) {
      const delay = RETRY_DELAY * (MAX_RETRIES - retries + 1);
      await new Promise(resolve => setTimeout(resolve, delay));
      return fetchWithRetry(url, options, retries - 1);
    }
    
    return response;
  } catch (error) {
    if (retries > 0) {
      const delay = RETRY_DELAY * (MAX_RETRIES - retries + 1);
      await new Promise(resolve => setTimeout(resolve, delay));
      return fetchWithRetry(url, options, retries - 1);
    }
    throw error;
  }
}

async function createHmacSignature(secret: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signatureBuffer = await crypto.subtle.sign("HMAC", key, enc.encode(message));
  const hashArray = Array.from(new Uint8Array(signatureBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
  return hashHex;
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
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    // Check rate limit
    if (!checkRateLimit(user.id)) {
      return new Response(JSON.stringify({ 
        error: "Rate limit exceeded. Please try again later." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 429,
      });
    }

    // Get API key for Binance
    const { data: apiKeyData, error: apiKeyError } = await supabase
      .from("user_api_keys")
      .select("api_key_encrypted, api_secret_encrypted")
      .eq("user_id", user.id)
      .eq("exchange", "Binance")
      .limit(1)
      .single();

    if (apiKeyError || !apiKeyData) {
      return new Response(JSON.stringify({ 
        error: "No Binance API key found. Please add one in Settings." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404,
      });
    }

    const encryptionKeyString = Deno.env.get("API_ENCRYPTION_KEY");
    if (!encryptionKeyString) {
      console.error("API_ENCRYPTION_KEY not found in environment");
      return new Response(JSON.stringify({ 
        error: "Server configuration error. Please contact support." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    let apiKey: string;
    let apiSecret: string;

    try {
      const keyData = new TextEncoder().encode(encryptionKeyString);
      const cryptoKey = await crypto.subtle.importKey(
        "raw", 
        keyData, 
        { name: "AES-GCM" }, 
        true, 
        ["encrypt", "decrypt"]
      );

      apiKey = await decrypt(apiKeyData.api_key_encrypted, cryptoKey);
      apiSecret = await decrypt(apiKeyData.api_secret_encrypted, cryptoKey);
    } catch (decryptError) {
      console.error("Decryption error:", decryptError);
      return new Response(JSON.stringify({ 
        error: "Failed to decrypt API credentials. Please re-add your API key." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    // Get existing symbols
    const { data: existingSymbols, error: symbolsError } = await supabase
      .from("trades")
      .select("symbol")
      .eq("user_id", user.id);

    if (symbolsError) {
      console.error("Error fetching user symbols:", symbolsError);
      return new Response(JSON.stringify({ 
        error: "Failed to fetch your trading symbols." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    const symbols = [...new Set(existingSymbols?.map(t => t.symbol) || [])];
    if (symbols.length === 0) {
      return new Response(JSON.stringify({ 
        message: "No trading symbols found. Add some trades first to sync." 
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    let syncedCount = 0;
    const errors: string[] = [];

    for (const symbol of symbols) {
      try {
        const timestamp = Date.now();
        const queryString = `symbol=${symbol}&timestamp=${timestamp}`;
        const signature = await createHmacSignature(apiSecret, queryString);

        const url = `${BINANCE_API_URL}/api/v3/myTrades?${queryString}&signature=${signature}`;
        
        const response = await fetchWithRetry(url, {
          headers: { "X-MBX-APIKEY": apiKey },
        });

        if (!response.ok) {
          const errorText = await response.text();
          console.error(`Binance API error for ${symbol}:`, errorText);
          
          // Handle specific Binance errors
          if (response.status === 401) {
            return new Response(JSON.stringify({ 
              error: "Invalid API key or signature. Please check your Binance API settings." 
            }), {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
              status: 401,
            });
          } else if (response.status === 429) {
            errors.push(`Rate limit hit for ${symbol}. Skipping...`);
            continue;
          } else {
            errors.push(`Failed to fetch ${symbol}: ${response.status}`);
            continue;
          }
        }

        const trades = await response.json();
        if (!Array.isArray(trades)) {
          errors.push(`Invalid response format for ${symbol}`);
          continue;
        }

        if (trades.length === 0) continue;

        const tradesToInsert = trades.map(trade => ({
          user_id: user.id,
          symbol: trade.symbol,
          exchange_trade_id: trade.id.toString(),
          direction: trade.isBuyer ? "Long" : "Short",
          entry_price: parseFloat(trade.price),
          exit_price: parseFloat(trade.price),
          quantity: parseFloat(trade.qty),
          notes: `Synced from Binance. Commission: ${trade.commission} ${trade.commissionAsset}`,
          created_at: new Date(trade.time).toISOString(),
        }));

        const { error: insertError } = await supabase
          .from("trades")
          .upsert(tradesToInsert, { onConflict: 'exchange_trade_id, user_id' });

        if (insertError) {
          console.error(`Database error for ${symbol}:`, insertError);
          errors.push(`Failed to save ${symbol} trades: ${insertError.message}`);
        } else {
          syncedCount += tradesToInsert.length;
        }

        // Add delay between symbols to avoid rate limits
        await new Promise(resolve => setTimeout(resolve, 500));

      } catch (symbolError) {
        console.error(`Unexpected error for ${symbol}:`, symbolError);
        errors.push(`Unexpected error processing ${symbol}`);
      }
    }

    const response = {
      message: `Sync completed. ${syncedCount} trades processed.`,
      syncedCount,
      errors: errors.length > 0 ? errors : undefined,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Sync error:", error);
    return new Response(JSON.stringify({ 
      error: error.message || "An unexpected error occurred during sync." 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});