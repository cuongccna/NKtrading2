import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// *** FIX: Thêm lại dòng khai báo hằng số API URL ***
const COVALENT_API_URL = "https://api.covalenthq.com/v1";

// Hàm để phân tích một giao dịch và tìm ra lệnh swap hoặc receive
function parseTransaction(tx: any, userAddress: string) {
  if (!tx.log_events || tx.log_events.length === 0) {
    return null;
  }

  const userAddressLower = userAddress.toLowerCase();

  // --- Ưu tiên phân tích SWAP trước ---
  const transfers = tx.log_events.filter(
    (log: any) => log.decoded?.name === "Transfer" && log.decoded.params
  );

  if (transfers.length >= 2) {
    const sentEvent = transfers.find(log => log.decoded.params[0].value.toLowerCase() === userAddressLower);
    const receivedEvent = transfers.find(log => log.decoded.params[1].value.toLowerCase() === userAddressLower);

    if (sentEvent && receivedEvent) {
      const amountOut = parseFloat(sentEvent.decoded.params[2].value) / (10 ** sentEvent.sender_contract_decimals);
      const amountIn = parseFloat(receivedEvent.decoded.params[2].value) / (10 ** receivedEvent.sender_contract_decimals);
      
      if (amountIn > 0 && amountOut > 0) {
        return {
          symbol: `${receivedEvent.sender_contract_ticker_symbol}/${sentEvent.sender_contract_ticker_symbol}`,
          direction: "Long",
          entry_price: amountOut / amountIn,
          exit_price: amountOut / amountIn,
          quantity: amountIn,
          notes: `Swap ${amountOut.toFixed(4)} ${sentEvent.sender_contract_ticker_symbol} for ${amountIn.toFixed(4)} ${receivedEvent.sender_contract_ticker_symbol}`,
          tx_hash: tx.tx_hash,
          created_at: tx.block_signed_at,
        };
      }
    }
  }
  
  // --- Nếu không phải SWAP, kiểm tra xem có phải là giao dịch RECEIVE đơn giản không ---
  if (transfers.length === 1) {
    const receiveEvent = transfers[0];
    const params = receiveEvent.decoded.params;
    
    // Kiểm tra xem người dùng có phải là người nhận không
    if (params && params[1] && params[1].value.toLowerCase() === userAddressLower) {
      const amountIn = parseFloat(params[2].value) / (10 ** receiveEvent.sender_contract_decimals);
      if (amountIn > 0) {
         return {
          symbol: `${receiveEvent.sender_contract_ticker_symbol}/USD`, // Giả định là mua bằng USD
          direction: "Long",
          entry_price: 0, // Không xác định được giá từ giao dịch Receive
          exit_price: 0,
          quantity: amountIn,
          notes: `Received ${amountIn.toFixed(4)} ${receiveEvent.sender_contract_ticker_symbol}`,
          tx_hash: tx.tx_hash,
          created_at: tx.block_signed_at,
        };
      }
    }
  }

  return null; // Không phải loại giao dịch hỗ trợ
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

    const { walletAddress, blockchain } = await req.json();
    if (!walletAddress || !blockchain) {
      throw new Error("Missing walletAddress or blockchain");
    }

    const covalentApiKey = Deno.env.get("COVALENT_API_KEY");
    if (!covalentApiKey) throw new Error("Covalent API key not found in Vault.");

    const chainId = "56"; // Chỉ hỗ trợ BSC
    const url = `${COVALENT_API_URL}/${chainId}/address/${walletAddress}/transactions_v2/?key=${covalentApiKey}`;

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch data from Covalent: ${await response.text()}`);
    }

    const data = await response.json();
    if (!data.data || !data.data.items) {
       return new Response(JSON.stringify({ message: "No transactions found for this address." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    
    const transactions = data.data.items;
    
    const tradesToInsert = [];
    for (const tx of transactions) {
      const parsedTrade = parseTransaction(tx, walletAddress);
      if (parsedTrade) {
        tradesToInsert.push({
          user_id: user.id,
          ...parsedTrade,
        });
      }
    }

    if (tradesToInsert.length === 0) {
      return new Response(JSON.stringify({ message: "No new supported transactions found." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: insertError } = await supabase
      .from("trades")
      .upsert(tradesToInsert, { onConflict: 'user_id, tx_hash' });

    if (insertError) throw insertError;

    return new Response(JSON.stringify({ message: `Sync completed. ${tradesToInsert.length} new transactions processed.` }), {
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