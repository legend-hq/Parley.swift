import { ParleyClient } from "../client.js";

// Test data builders
function createPortfolio(walletAddress, chainId = 8453) {
  // Base mainnet
  return {
    wallets: [
      {
        has_code: true,
        is_quark: true,
        quark_version: "1.0",
        wallet: walletAddress,
      },
    ],
    block: {
      number: 5783614,
      timestamp: fixedTimestamp,
    },
    chain_id: chainId,
    aave_markets: [],
    comets: [],
    morpho_markets: [],
    morpho_vaults: [],
    query_version: {
      revision: 1,
      schema: "2025-03-27",
    },
    tokens: [
      {
        symbol: "USDC",
        name: "USD Coin",
        address: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
        decimals: 6,
        usd_price: {
          type: "decimal",
          precision: 18,
          uint_string: "1000000000000000000",
        },
        balances: [
          {
            wallet: walletAddress,
            balance: {
              type: "decimal",
              precision: 6,
              uint_string: "10000000000",
            }, // 10,000 USDC
          },
        ],
      },
      {
        symbol: "WETH",
        name: "Wrapped Ether",
        address: "0x4200000000000000000000000000000000000006",
        decimals: 18,
        usd_price: {
          type: "decimal",
          precision: 18,
          uint_string: "3000000000000000000000",
        },
        balances: [
          {
            wallet: walletAddress,
            balance: {
              type: "decimal",
              precision: 18,
              uint_string: "5000000000000000000",
            }, // 5 ETH
          },
        ],
      },
    ],
    morpho_reward_positions: [],
    quark_nonce_statuses: [],
    across_fill_statuses: [],
    token_wrapper_quotes: [],
  };
}

function createQuote(timestamp = fixedTimestamp) {
  const issuedAt = timestamp;
  const expiresAt = timestamp + 3600; // 1 hour later

  return {
    quote_id:
      "0x00000000000000000000000000000000000000000000000000000000000000CC",
    issued_at: issuedAt,
    expires_at: expiresAt,
    asset_quotes: [
      {
        token_symbol: "USDC",
        market_price_usd: "1000000000000000000", // $1.00
        adjusted_price_usd: "999900000000000000", // $0.9999
      },
      {
        token_symbol: "ETH",
        market_price_usd: "3000000000000000000000", // $3000.00
        adjusted_price_usd: "2999000000000000000000", // $2999.00
      },
      {
        token_symbol: "WBTC",
        market_price_usd: "50000000000000000000000", // $50000.00
        adjusted_price_usd: "49990000000000000000000", // $49990.00
      },
      {
        token_symbol: "WETH",
        market_price_usd: "3000000000000000000000", // $3000.00
        adjusted_price_usd: "3000000000000000000000", // $3000.00
      },
    ],
    network_operation_fees: [
      {
        chain_id: 8453, // Base
        operation_type: "transfer",
        usd_price: "100000000000000000", // $0.10
      },
      {
        chain_id: 8453,
        operation_type: "swap",
        usd_price: "500000000000000000", // $0.50
      },
      {
        chain_id: 8453,
        operation_type: "aaveSupply",
        usd_price: "1000000000000000000", // $1.00
      },
      {
        chain_id: 8453,
        operation_type: "aaveWithdraw",
        usd_price: "1500000000000000000", // $1.50
      },
    ],
  };
}

// Test cases
// Fixed timestamp for deterministic tests
const fixedTimestamp = 1735257035; // 2024-12-26 20:57:15 UTC

const testCases = [
  {
    name: "Transfer USDC on Base",
    request: {
      version: "1.0",
      intent: {
        intent_type: "transfer",
        block_timestamp: fixedTimestamp.toString(),
        payment_asset_symbol: "USDC",
        chain_id: "8453",
        asset_symbol: "USDC",
        amount: "1000000", // 1 USDC (6 decimals)
        sender: "0x00000000000000000000000000000000000a11ce",
        recipient: "0x00000000000000000000000000000000000b0b00",
      },
      portfolios: [
        createPortfolio("0x00000000000000000000000000000000000A11CE"),
      ],
      quote: createQuote(),
      across_quotes: [],
      nonce_secrets: [
        {
          chain_id: 8453,
          account: "0x00000000000000000000000000000000000a11ce",
          nonce_secret:
            "0x0000000000000000000000000000000000000000000000000000000000000001",
        },
      ],
    },
    expectSuccess: true,
    expectedChart: {
      quarkOperationActions: [
        {
          action: {
            actionContext: {
              action_type: "MULTI_ACTION",
              action_contexts: [
                {
                  token: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                  recipient: "0x00000000000000000000000000000000000b0b00",
                  price: "100000000",
                  amount: "1000000",
                  action_type: "TRANSFER",
                  chain_id: "8453",
                  asset_symbol: "USDC",
                },
                {
                  token: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                  chain_id: "8453",
                  action_type: "QUOTE_PAY",
                  quote_id:
                    "0x00000000000000000000000000000000000000000000000000000000000000cc",
                  amount: "100010",
                  price: "100000000",
                  payee: "0x7ea8d6119596016935543d90ee8f5126285060a1",
                  asset_symbol: "USDC",
                },
              ],
              action_types: ["TRANSFER", "QUOTE_PAY"],
            },
            nonceSecret:
              "0x0000000000000000000000000000000000000000000000000000000000000001",
            actionType: "MULTI_ACTION",
            totalPlays: "1",
            chainId: "8453",
            quarkAccount: "0x00000000000000000000000000000000000a11ce",
            executionType: "IMMEDIATE",
          },
          operation: {
            scriptAddress: "0x72e7e6ce7cb4d28ffe830708be3d30aee286ec24",
            scriptSources: [],
            scriptCalldata:
              "0x4d618e3b000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ab27b36e50792ec63f63ab4724b7c9b408feeac80000000000000000000000002d88262d93a9c5656c1703ec03e78ba65c90a8f00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000084d9931842000000000000000000000000833589fcd6edb6e08f4c7c32d4f71b54bda0291300000000000000000000000000000000000000000000000000000000000b0b0000000000000000000000000000000000000000000000000000000000000f424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000843e8bca680000000000000000000000007ea8d6119596016935543d90ee8f5126285060a1000000000000000000000000833589fcd6edb6e08f4c7c32d4f71b54bda0291300000000000000000000000000000000000000000000000000000000000186aa00000000000000000000000000000000000000000000000000000000000000cc00000000000000000000000000000000000000000000000000000000",
            expiry: "1735861835",
            isReplayable: false,
            nonce:
              "0x0000000000000000000000000000000000000000000000000000000000000001",
          },
        },
      ],
      paymentCurrency: "USDC",
      version: "1.0.0",
      eip712Data: {
        hashStruct:
          "0xbf576e4b4d55ec1a30244c1d507448a60207b8f3b7e1789a75be015fbb392bef",
        domainSeparator:
          "0xe436d66fbfc2f4392a6c86846eb463fed38a80892d1b458e0e173ef78a210947",
        digest:
          "0x9c213643824d015550c08570ce2951042d08acabfd66a0bcc4d73a3787d1cd58",
      },
    },
  },
  /*{ // Skip - Aave operations not implemented in Tradewinds yet
        name: "Aave Supply USDC on Base",
        request: {
            version: "1.0",
            intent: {
                intent_type: "aave_supply",
                block_timestamp: Math.floor(Date.now() / 1000).toString(),
                payment_asset_symbol: "USDC",
                amount: "50000000", // 50 USDC
                asset_symbol: "USDC",
                chain_id: "8453",
                aave_pool: "0xa238dd80c259a72e81d7e4664a9801593f98d1c5", // Aave V3 Base
                sender: "0x00000000000000000000000000000000000a11ce"
            },
            portfolios: [createPortfolio("0x00000000000000000000000000000000000A11CE", 8453, true)],
            quote: createQuote(),
            across_quotes: [],
            nonce_secrets: [{
                chain_id: 8453,
                account: "0x00000000000000000000000000000000000a11ce",
                nonce_secret: "0x0000000000000000000000000000000000000000000000000000000000000001"
            }]
        },
        expectSuccess: true
    },*/
  /*{ // Skip - Swap operations not implemented in Tradewinds yet
        name: "Swap ETH to USDC",
        request: {
            version: "1.0",
            intent: {
                intent_type: "swap",
                block_timestamp: Math.floor(Date.now() / 1000).toString(),
                payment_asset_symbol: "USDC",
                chain_id: "8453",
                sell_token: "0x4200000000000000000000000000000000000006", // WETH on Base
                sell_amount: "1000000000000000000", // 1 ETH
                buy_token: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913", // USDC on Base
                buy_amount: "3000000000", // ~3000 USDC
                swap_quote_sell_amount: "1000000000000000000",
                swap_quote_buy_amount: "3000000000",
                fee_token: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                fee_amount: "0",
                sender: "0x00000000000000000000000000000000000a11ce",
                is_exact_out: false,
                is_buy: false
            },
            portfolios: [createPortfolio("0x00000000000000000000000000000000000A11CE")],
            quote: createQuote(),
            across_quotes: [],
            nonce_secrets: [{
                chain_id: 8453,
                account: "0x00000000000000000000000000000000000a11ce",
                nonce_secret: "0x0000000000000000000000000000000000000000000000000000000000000001"
            }]
        },
        expectSuccess: true
    }*/
];

// Bun test runner
import { test, expect, beforeAll } from "bun:test";

let client;

// Setup before all tests
beforeAll(async () => {
  client = new ParleyClient("../.build/debug/Parley.wasm");
  await client.initialize();
});

// Run each test case
testCases.forEach((testCase) => {
  test(testCase.name, async () => {
    try {
      console.log(`\nRunning test: ${testCase.name}`);
      const result = await client.chart(testCase.request);

      if (testCase.expectSuccess) {
        expect(result.chart).toBeDefined();
        expect(result.error).toBeUndefined();

        // Deep comparison with expected output if provided
        if (testCase.expectedChart) {
          expect(result.chart).toEqual(testCase.expectedChart);
        } else {
          // Basic validation of chart structure
          expect(result.chart).toHaveProperty("version");
          expect(result.chart).toHaveProperty("quarkOperationActions");
          expect(Array.isArray(result.chart.quarkOperationActions)).toBe(true);

          // Log summary
          console.log(
            `✓ ${testCase.name}: Generated ${result.chart.quarkOperationActions.length} operation actions`,
          );

          // Only log full output if explicitly requested
          if (testCase.logOutput) {
            console.log(
              "Actual chart output:",
              JSON.stringify(result.chart, null, 2),
            );
          }
        }
      } else {
        expect(result.chart).toBeUndefined();
        expect(result.error).toBeDefined();
      }
    } catch (error) {
      if (testCase.expectSuccess) {
        throw error;
      }
      // Expected error case
      console.log(`✓ ${testCase.name}: Expected error: ${error.message}`);
    }
  });
});

// Error handling test
test("Invalid intent structure", async () => {
  const invalidRequest = {
    version: "1.0",
    intent: { invalid: "intent" },
    portfolios: [],
    quote: createQuote(),
    across_quotes: [],
    nonce_secrets: [],
  };

  await expect(client.chart(invalidRequest)).rejects.toThrow();
});

// Test with complex portfolio
test("Complex portfolio with token balances", async () => {
  const portfolio = createPortfolio(
    "0x00000000000000000000000000000000000A11CE",
  );

  // Override with specific token balance for this test
  portfolio.tokens = [
    {
      symbol: "USDC",
      name: "USD Coin",
      address: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
      decimals: 6,
      usd_price: {
        type: "decimal",
        precision: 18,
        uint_string: "1000000000000000000",
      },
      balances: [
        {
          wallet: "0x00000000000000000000000000000000000a11ce",
          balance: {
            type: "decimal",
            precision: 6,
            uint_string: "100000000",
          }, // 100 USDC
        },
      ],
    },
  ];

  const request = {
    version: "1.0",
    intent: {
      intent_type: "transfer",
      block_timestamp: fixedTimestamp.toString(),
      payment_asset_symbol: "USDC",
      chain_id: "8453",
      asset_symbol: "USDC",
      amount: "50000000", // 50 USDC
      sender: "0x00000000000000000000000000000000000a11ce",
      recipient: "0x00000000000000000000000000000000000b0b00",
    },
    portfolios: [portfolio],
    quote: createQuote(),
    across_quotes: [],
    nonce_secrets: [
      {
        chain_id: 8453,
        account: "0x00000000000000000000000000000000000a11ce",
        nonce_secret:
          "0x0000000000000000000000000000000000000000000000000000000000000001",
      },
    ],
  };

  const result = await client.chart(request);
  expect(result).toBeDefined();

  // Check if we got an error instead of a chart
  if (result.error) {
    console.error(`Unexpected error in complex portfolio test:`, result.error);
    throw new Error(
      `Expected success but got error: ${JSON.stringify(result.error)}`,
    );
  }

  expect(result.chart).toBeDefined();
  expect(result.error).toBeUndefined();

  if (result.chart) {
    expect(result.chart).toHaveProperty("version");
    expect(result.chart).toHaveProperty("quarkOperationActions");
    console.log(
      `✓ Complex portfolio test: Generated ${result.chart.quarkOperationActions.length} operation actions`,
    );
  }
});
