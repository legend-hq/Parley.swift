import Charter
import Eth
import Foundation
import Prelude
import SwiftNumber
import Testing

@testable import Portfolio

@Suite("ActivityMetadata Decoding Tests")
struct ActivityMetadataDecodingTests {
    
    let decoder = JSONDecoder()
    
    init() {
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Handle ISO 8601 format with or without fractional seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
    }
    
    @Test("Decode ActivityMetadata with MultiAction")
    func decodeActivityMetadataWithMultiAction() throws {
        let jsonString = """
        {
          "success": true,
          "from": "0xc4c4cc6385cbf4b8b31d1c97b64fbfde12f11a0b",
          "to": "0xd75c8c5f5d1fd11f14b1fb2c92733cd5a25e4232",
          "updated_at": "2025-10-20T22:02:07Z",
          "gas_used": "612883",
          "chain_id": 480,
          "transaction_hash": "0xb66e6ab30e5c648af1f2dc90d688b44fff0932bd8d7df2ed00fde8be44ccf1cf",
          "gas_price": "1000371",
          "expiry": 1761602489,
          "quark_wallet_address": "0xd75c8c5f5d1fd11f14b1fb2c92733cd5a25e4232",
          "payment_method": "token",
          "semantic_events": [
            {
              "event_type": "morpho_vault_supply",
              "log_indices": [22, 23, 24],
              "event_metadata": {
                "token": "0x79A02482A880bCE3F13e09Da970dC34db4CD24d1",
                "amount": "9995648",
                "morpho_vault": "0xb1E80387EbE53Ff75a89736097D34dC8D9E9045B",
                "dollar_value": "999369885"
              }
            },
            {
              "event_type": "quote_pay",
              "log_indices": [16],
              "event_metadata": {
                "token": "0x79A02482A880bCE3F13e09Da970dC34db4CD24d1",
                "amount": "3184",
                "quote_id": "0xa40d6bcbae9e2097f05a49ad7ba9b85db2c0ba77af66c285cf60abc8541ed8b3",
                "payee": "0x7ea8d6119596016935543d90Ee8f5126285060A1",
                "dollar_value": "318338"
              }
            }
          ],
          "quark_wallet_id": 2118,
          "quark_operation_nonce": "0xec8e9f416c24f1b0f1444e319f5640c4e0c3af057b2095718ceb523722bcff8b",
          "quark_operation_id": 2668,
          "activity_record_type": "executed",
          "action_type": "MULTI_ACTION",
          "action_context": {
            "action_types": ["QUOTE_PAY", "MORPHO_VAULT_SUPPLY"],
            "action_contexts": [
              {
                "token": "0x79a02482a880bce3f13e09da970dc34db4cd24d1",
                "amount": "3184",
                "chain_id": "480",
                "asset_symbol": "USDC",
                "quote_id": "0xa40d6bcbae9e2097f05a49ad7ba9b85db2c0ba77af66c285cf60abc8541ed8b3",
                "price": "99980500",
                "payee": "0x7ea8d6119596016935543d90ee8f5126285060a1"
              },
              {
                "token": "0x79a02482a880bce3f13e09da970dc34db4cd24d1",
                "amount": "9995648",
                "chain_id": "480",
                "asset_symbol": "USDC",
                "morpho_vault": "0xb1e80387ebe53ff75a89736097d34dc8d9e9045b",
                "price": "99980500"
              }
            ]
          },
          "reverted_at": null,
          "gas_overhead": "0",
          "executed_at_block_number": 20831042,
          "revert_values": null,
          "revert_signature": null,
          "revert_reason": null,
          "quark_execution_id": 2631,
          "gas_estimate": "",
          "executed_at": "2025-10-20T22:02:06Z"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // Decode the activity metadata
        let metadata = try decoder.decode(ActivityMetadata.self, from: jsonData)
        
        // Verify basic fields
        #expect(metadata.success == true)
        #expect(metadata.quarkOperationId == 2668)
        #expect(metadata.quarkOperationNonce == Hex("0xec8e9f416c24f1b0f1444e319f5640c4e0c3af057b2095718ceb523722bcff8b"))
        #expect(metadata.quarkWalletAddress == EthAddress("0xd75c8c5f5d1fd11f14b1fb2c92733cd5a25e4232"))
        #expect(metadata.network == Network.worldChain)
        #expect(metadata.transactionHash == Hex("0xb66e6ab30e5c648af1f2dc90d688b44fff0932bd8d7df2ed00fde8be44ccf1cf"))
        #expect(metadata.executedAtBlockNumber == 20831042)
        #expect(metadata.activityRecordType == .executed)
        
        // Verify semantic events
        #expect(metadata.semanticEventContexts.count == 2)
        
        // Semantic events are sorted by first log index, so quote_pay (16) comes before morpho_vault_supply (22)
        // First semantic event - quote_pay
        let quotePayEvent = metadata.semanticEventContexts[0]
        #expect(quotePayEvent.eventType == .quotePay)
        #expect(quotePayEvent.logIndices == [16])
        
        // Second semantic event - morpho_vault_supply  
        let morphoEvent = metadata.semanticEventContexts[1]
        #expect(morphoEvent.eventType == .morphoVaultSupply)
        #expect(morphoEvent.logIndices == [22, 23, 24])
        
        // Verify action context
        #expect(metadata.actionContext != nil)
        
        if case .multiAction(let actions) = metadata.actionContext {
            #expect(actions.count == 2)
            
            // First action - quote pay
            if case .quotePay(let quotePay) = actions[0] {
                #expect(quotePay.amount == Number("3184"))
                #expect(quotePay.assetSymbol == "USDC")
                #expect(quotePay.chainId == Number("480"))
                #expect(quotePay.token == EthAddress("0x79a02482a880bce3f13e09da970dc34db4cd24d1"))
                #expect(quotePay.quoteId == Hex("0xa40d6bcbae9e2097f05a49ad7ba9b85db2c0ba77af66c285cf60abc8541ed8b3"))
                #expect(quotePay.payee == EthAddress("0x7ea8d6119596016935543d90ee8f5126285060a1"))
                #expect(quotePay.price == Number("99980500"))
            } else {
                Issue.record("Expected first action to be quotePay")
            }
            
            // Second action - morpho vault supply
            if case .morphoVaultSupply(let morphoSupply) = actions[1] {
                #expect(morphoSupply.amount == Number("9995648"))
                #expect(morphoSupply.assetSymbol == "USDC")
                #expect(morphoSupply.chainId == Number("480"))
                #expect(morphoSupply.token == EthAddress("0x79a02482a880bce3f13e09da970dc34db4cd24d1"))
                #expect(morphoSupply.morphoVault == EthAddress("0xb1e80387ebe53ff75a89736097d34dc8d9e9045b"))
                #expect(morphoSupply.price == Number("99980500"))
            } else {
                Issue.record("Expected second action to be morphoVaultSupply")
            }
        } else {
            Issue.record("Expected action context to be multiAction")
        }
    }
    
    @Test("Decode ActivityMetadata with single Transfer action")
    func decodeActivityMetadataWithTransfer() throws {
        let jsonString = """
        {
          "success": true,
          "chain_id": 1,
          "transaction_hash": "0x1234567890123456789012345678901234567890123456789012345678901234",
          "quark_wallet_address": "0x1234567890123456789012345678901234567890",
          "quark_operation_nonce": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
          "quark_operation_id": 100,
          "semantic_events": [],
          "activity_record_type": "executed",
          "action_type": "TRANSFER",
          "action_context": {
            "amount": "1000000",
            "asset_symbol": "USDC",
            "chain_id": "1",
            "price": "1000000000000000000",
            "recipient": "0x9876543210987654321098765432109876543210",
            "token": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
          },
          "executed_at": "2025-10-20T12:00:00Z",
          "executed_at_block_number": 20000000
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // Decode the activity metadata
        let metadata = try decoder.decode(ActivityMetadata.self, from: jsonData)
        
        // Verify basic fields
        #expect(metadata.success == true)
        #expect(metadata.quarkOperationId == 100)
        #expect(metadata.network == Network.ethereum)
        
        // Verify action context
        #expect(metadata.actionContext != nil)
        
        if case .transfer(let transfer) = metadata.actionContext {
            #expect(transfer.amount == Number("1000000"))
            #expect(transfer.assetSymbol == "USDC")
            #expect(transfer.chainId == Number("1"))
            #expect(transfer.price == Number("1000000000000000000"))
            #expect(transfer.recipient == .ethereum(EthAddress("0x9876543210987654321098765432109876543210")))
            #expect(transfer.token == .ethereum(EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")))
        } else {
            Issue.record("Expected action context to be transfer")
        }
    }
}
