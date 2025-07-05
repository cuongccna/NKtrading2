import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const COVALENT_API_URL = "https://api.covalenthq.com/v1";

// Hàm để phân tích một giao dịch và tìm ra lệnh swap
function parseSwapTransaction(tx: any, userAddress: string) {
  if (!tx.log_events || tx.log_events.length < 2) {
    return null; // Cần ít nhất 2 sự kiện transfer
  }

  const transfers = tx.log_events.filter(
    (log: any) => log.decoded?.name === "Transfer" && log.decoded.params
  );

  if (transfers.length < 2) {
    return null;
  }

  const userAddressLower = userAddress.toLowerCase();

  // Tìm token người dùng gửi đi (from = userAddress)
  const sentEvent = transfers.find(
    (log: any) => log.decoded.params[0].value.toLowerCase() === userAddressLower
  );

  // Tìm token người dùng nhận về (to = userAddress)
  const receivedEvent = transfers.find(
    (log: any) => log.decoded.params[1].value.toLowerCase() === userAddressLower
  );

  if (!sentEvent || !receivedEvent) {
    return null; // Không phải là một giao dịch swap đơn giản
  }

  const tokenOut = sentEvent.sender_name;
  const tokenIn = receivedEvent.sender_name;
  const symbolOut = sentEvent.sender_contract_ticker_symbol;
  const symbolIn = receivedEvent.sender_contract_ticker_symbol;

  const amountOut = parseFloat(sentEvent.decoded.params[2].value) / (10 ** sentEvent.sender_contract_decimals);
  const amountIn = parseFloat(receivedEvent.decoded.params[2].value) / (10 ** receivedEvent.sender_contract_decimals);

  if (amountIn === 0 || amountOut === 0) return null;

  // Tính toán giá, coi như là giá của token mua vào (tokenIn) theo token bán ra (tokenOut)
  const price = amountOut / amountIn;

  return {
    symbol: `${symbolIn}/${symbolOut}`,
    direction: "Long", // Mua tokenIn
    entry_price: price,
    exit_price: price, // Đối với một swap, giá vào và ra là một
    quantity: amountIn,
    notes: `Swap ${amountOut.toFixed(4)} ${symbolOut} for ${amountIn.toFixed(4)} ${symbolIn}`,
    tx_hash: tx.tx_hash,
    created_at: tx.block_signed_at,
  };
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

    // Hiện tại chỉ hỗ trợ BNB Smart Chain
    const chainId = "56"; 
    const url = `${COVALENT_API_URL}/${chainId}/address/${walletAddress}/transactions_v2/?key=${covalentApiKey}`;

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch data from Covalent: ${await response.text()}`);
    }

    const data = await response.json();
    const transactions = data.data.items;
    
    const tradesToInsert = [];
    for (const tx of transactions) {
      const parsedTrade = parseSwapTransaction(tx, walletAddress);
      if (parsedTrade) {
        tradesToInsert.push({
          user_id: user.id,
          ...parsedTrade,
        });
      }
    }

    if (tradesToInsert.length === 0) {
      return new Response(JSON.stringify({ message: "No new swap transactions found." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Dùng upsert để thêm mới hoặc bỏ qua nếu đã tồn tại dựa trên tx_hash
    const { error: insertError } = await supabase
      .from("trades")
      .upsert(tradesToInsert, { onConflict: 'user_id, tx_hash' });

    if (insertError) throw insertError;

    return new Response(JSON.stringify({ message: `Sync completed. ${tradesToInsert.length} new transactions found.` }), {
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