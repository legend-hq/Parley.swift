import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Charter

@Suite("ActionContext Optional Fee Decoding Tests")
struct ActionContextOptionalFeeDecodingTests {

    let decoder = JSONDecoder()

    // MARK: - LoopLongActionContext Tests

    @Test("LoopLongActionContext decodes with fee fields present")
    func loopLongWithFees() throws {
        let json = """
        {
            "action_type": "LOOP_LONG",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "max_swap_backing_amount": "1000000000",
                "max_provided_backing_amount": "500000000",
                "chain_id": "8453",
                "is_increase": true,
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                "fee_amount": "1000000",
                "fee_asset_symbol": "USDC",
                "fee_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "fee_token_price": "100000000"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .loopLong(let context) = decoded else {
            Issue.record("Expected loopLong action context")
            return
        }

        #expect(context.feeAmount == Number("1000000"))
        #expect(context.feeAssetSymbol == "USDC")
        #expect(context.feeToken == EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"))
        #expect(context.feeTokenPrice == Number("100000000"))
    }

    @Test("LoopLongActionContext decodes without fee fields, defaults to backing asset")
    func loopLongWithoutFees() throws {
        let json = """
        {
            "action_type": "LOOP_LONG",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "max_swap_backing_amount": "1000000000",
                "max_provided_backing_amount": "500000000",
                "chain_id": "8453",
                "is_increase": true,
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .loopLong(let context) = decoded else {
            Issue.record("Expected loopLong action context")
            return
        }

        // Fee fields should default to backing asset with zero amount
        #expect(context.feeAmount == .zero)
        #expect(context.feeAssetSymbol == "USDC")
        #expect(context.feeToken == EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"))
        #expect(context.feeTokenPrice == Number("100000000"))
    }

    // MARK: - LoopShortActionContext Tests

    @Test("LoopShortActionContext decodes with fee fields present")
    func loopShortWithFees() throws {
        let json = """
        {
            "action_type": "LOOP_SHORT",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "min_swap_backing_amount": "900000000",
                "provided_backing_amount": "1000000000",
                "chain_id": "8453",
                "is_increase": false,
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                "fee_amount": "500000",
                "fee_asset_symbol": "USDC",
                "fee_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "fee_token_price": "100000000"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .loopShort(let context) = decoded else {
            Issue.record("Expected loopShort action context")
            return
        }

        #expect(context.feeAmount == Number("500000"))
        #expect(context.feeAssetSymbol == "USDC")
    }

    @Test("LoopShortActionContext decodes without fee fields, defaults to backing asset")
    func loopShortWithoutFees() throws {
        let json = """
        {
            "action_type": "LOOP_SHORT",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "min_swap_backing_amount": "900000000",
                "provided_backing_amount": "1000000000",
                "chain_id": "8453",
                "is_increase": false,
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .loopShort(let context) = decoded else {
            Issue.record("Expected loopShort action context")
            return
        }

        #expect(context.feeAmount == .zero)
        #expect(context.feeAssetSymbol == "USDC")
        #expect(context.feeToken == EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"))
        #expect(context.feeTokenPrice == Number("100000000"))
    }

    // MARK: - UnloopLongActionContext Tests

    @Test("UnloopLongActionContext decodes with fee fields present")
    func unloopLongWithFees() throws {
        let json = """
        {
            "action_type": "UNLOOP_LONG",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "min_swap_backing_amount": "900000000",
                "backing_amount_to_exit": "1000000000",
                "chain_id": "8453",
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                "fee_amount": "750000",
                "fee_asset_symbol": "USDC",
                "fee_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "fee_token_price": "100000000"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .unloopLong(let context) = decoded else {
            Issue.record("Expected unloopLong action context")
            return
        }

        #expect(context.feeAmount == Number("750000"))
        #expect(context.feeAssetSymbol == "USDC")
    }

    @Test("UnloopLongActionContext decodes without fee fields, defaults to backing asset")
    func unloopLongWithoutFees() throws {
        let json = """
        {
            "action_type": "UNLOOP_LONG",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "min_swap_backing_amount": "900000000",
                "backing_amount_to_exit": "1000000000",
                "chain_id": "8453",
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .unloopLong(let context) = decoded else {
            Issue.record("Expected unloopLong action context")
            return
        }

        #expect(context.feeAmount == .zero)
        #expect(context.feeAssetSymbol == "USDC")
        #expect(context.feeToken == EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"))
        #expect(context.feeTokenPrice == Number("100000000"))
    }

    // MARK: - UnloopShortActionContext Tests

    @Test("UnloopShortActionContext decodes with fee fields present")
    func unloopShortWithFees() throws {
        let json = """
        {
            "action_type": "UNLOOP_SHORT",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "max_swap_backing_amount": "1100000000",
                "chain_id": "8453",
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                "fee_amount": "250000",
                "fee_asset_symbol": "USDC",
                "fee_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "fee_token_price": "100000000"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .unloopShort(let context) = decoded else {
            Issue.record("Expected unloopShort action context")
            return
        }

        #expect(context.feeAmount == Number("250000"))
        #expect(context.feeAssetSymbol == "USDC")
    }

    @Test("UnloopShortActionContext decodes without fee fields, defaults to backing asset")
    func unloopShortWithoutFees() throws {
        let json = """
        {
            "action_type": "UNLOOP_SHORT",
            "action_context": {
                "backing_asset_symbol": "USDC",
                "backing_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "backing_token_price": "100000000",
                "max_swap_backing_amount": "1100000000",
                "chain_id": "8453",
                "exposure_amount": "1000000000000000000",
                "exposure_asset_symbol": "ETH",
                "exposure_token": "0x4200000000000000000000000000000000000006",
                "exposure_token_price": "300000000000",
                "swap_venue": "uniswap_v3",
                "borrow_venue": "morpho_blue",
                "borrow_market_id": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .unloopShort(let context) = decoded else {
            Issue.record("Expected unloopShort action context")
            return
        }

        #expect(context.feeAmount == .zero)
        #expect(context.feeAssetSymbol == "USDC")
        #expect(context.feeToken == EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"))
        #expect(context.feeTokenPrice == Number("100000000"))
    }

    // MARK: - SwapActionContext Tests

    @Test("SwapActionContext decodes without legacy fee fields, defaults to empty arrays")
    func swapWithoutLegacyFees() throws {
        let json = """
        {
            "action_type": "SWAP",
            "action_context": {
                "chain_id": "8453",
                "input_amount": "1000000",
                "input_asset_symbol": "USDC",
                "input_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "input_token_price": "100000000",
                "output_amount": "500000000000000",
                "output_asset_symbol": "ETH",
                "output_token": "0x4200000000000000000000000000000000000006",
                "output_token_price": "300000000000",
                "is_exact_out": false,
                "is_buy": false,
                "is_capped_max": false,
                "use_filler": false
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .swap(let context) = decoded else {
            Issue.record("Expected swap action context")
            return
        }

        // Fee fields should default to empty arrays when not present
        #expect(context.feeAmounts.isEmpty)
        #expect(context.feeAssetSymbols.isEmpty)
        #expect(context.feeTokens.isEmpty)
        #expect(context.feeTokenPrices.isEmpty)
        #expect(context.feeDescriptions.isEmpty)
    }

    @Test("SwapActionContext decodes with array fee fields")
    func swapWithArrayFees() throws {
        let json = """
        {
            "action_type": "SWAP",
            "action_context": {
                "chain_id": "8453",
                "fee_amounts": ["1000000", "500000"],
                "fee_asset_symbols": ["USDC", "USDC"],
                "fee_tokens": ["0x833589fcd6edb6e08f4c7c32d4f71b54bda02913", "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"],
                "fee_token_prices": ["100000000", "100000000"],
                "fee_descriptions": ["LEGEND", "ZERO_EX"],
                "input_amount": "1000000",
                "input_asset_symbol": "USDC",
                "input_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "input_token_price": "100000000",
                "output_amount": "500000000000000",
                "output_asset_symbol": "ETH",
                "output_token": "0x4200000000000000000000000000000000000006",
                "output_token_price": "300000000000",
                "is_exact_out": false,
                "is_buy": false,
                "is_capped_max": false,
                "use_filler": false
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .swap(let context) = decoded else {
            Issue.record("Expected swap action context")
            return
        }

        #expect(context.feeAmounts == [Number("1000000"), Number("500000")])
        #expect(context.feeAssetSymbols == ["USDC", "USDC"])
        #expect(context.feeDescriptions == ["LEGEND", "ZERO_EX"])
    }

    @Test("SwapActionContext decodes with legacy singular fee fields")
    func swapWithLegacyFees() throws {
        let json = """
        {
            "action_type": "SWAP",
            "action_context": {
                "chain_id": "8453",
                "fee_amount": "1000000",
                "fee_asset_symbol": "USDC",
                "fee_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "fee_token_price": "100000000",
                "input_amount": "1000000",
                "input_asset_symbol": "USDC",
                "input_token": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                "input_token_price": "100000000",
                "output_amount": "500000000000000",
                "output_asset_symbol": "ETH",
                "output_token": "0x4200000000000000000000000000000000000006",
                "output_token_price": "300000000000",
                "is_exact_out": false,
                "is_buy": false,
                "is_capped_max": false,
                "use_filler": false
            }
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(Charter.ActionContext.self, from: json)

        guard case .swap(let context) = decoded else {
            Issue.record("Expected swap action context")
            return
        }

        // Legacy singular fields should be converted to arrays
        #expect(context.feeAmounts == [Number("1000000")])
        #expect(context.feeAssetSymbols == ["USDC"])
        #expect(context.feeTokens == [EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")])
        #expect(context.feeTokenPrices == [Number("100000000")])
        #expect(context.feeDescriptions == ["ZERO_EX"])
    }
}
