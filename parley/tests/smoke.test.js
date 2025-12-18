import { ParleyClient } from "../client.js";

// Simple smoke test runner
async function runTests() {
  console.log("🚀 Parley WASM Smoke Tests");
  console.log("==========================\n");

  const client = new ParleyClient("../.build/debug/Parley.wasm");
  await client.initialize();
  console.log("✅ WASM module loaded\n");

  // Test version and name functions
  console.log("ℹ️  Module Info");
  console.log("-------------");
  const version = await client.version();
  const name = await client.name();
  console.log(`  Name: ${name}`);
  console.log(`  Version: ${version}\n`);

  // Test 1: Basic chart function with minimal data
  console.log("📊 Test 1: Chart Function");
  console.log("------------------------");
  try {
    const now = new Date();
    const result = await client.chart({
      version: "1.0",
      intent: {
        intent_type: "transfer",
        block_timestamp: Math.floor(Date.now() / 1000).toString(),
        payment_asset_symbol: "USDC",
        // TransferIntent fields:
        chain_id: "8453",
        asset_symbol: "USDC",
        amount: "1000000",
        sender: "0x00000000000000000000000000000000000a11ce",
        recipient: "0x00000000000000000000000000000000000b0b00",
      },
      portfolios: [],
      quote: {
        quote_id:
          "0x00000000000000000000000000000000000000000000000000000000000000CC",
        issued_at: Math.floor(now.getTime() / 1000),
        expires_at: Math.floor((now.getTime() + 3600000) / 1000),
        asset_quotes: [],
        network_operation_fees: [],
      },
      across_quotes: [],
      nonce_secrets: [],
    });
    console.log("✓ Chart function called successfully");
    console.log(`  Result has chart: ${result.chart !== null}`);
    console.log(`  Result has error: ${result.error !== null}`);
    if (result.error) {
      console.log(`  Error message: ${JSON.stringify(result.error)}`);
    }
  } catch (error) {
    console.error("✗ Chart test failed:", error.message);
    process.exit(1);
  }

  // Test 2: Error handling with invalid data
  console.log("\n🔥 Test 2: Error Handling");
  console.log("-------------------------");
  try {
    await client.callJSON("chart", { invalid: "data" });
    console.error("✗ Error handling failed - should have thrown");
    process.exit(1);
  } catch (error) {
    console.log("✓ Error correctly caught:", error.message);
  }

  console.log("\n✨ All smoke tests passed!");
}

// Run the tests
runTests().catch((error) => {
  console.error("Test runner failed:", error);
  process.exit(1);
});
