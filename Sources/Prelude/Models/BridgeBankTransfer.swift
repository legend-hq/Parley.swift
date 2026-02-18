import Foundation

public extension LegendModel {

    // MARK: - Shared Types

    enum BridgeKycStatus: String, Codable, Equatable, Sendable {
        case notStarted = "not_started"
        case incomplete
        case pending
        case approved
        case rejected
    }

    enum PaymentRail: String, Codable, Equatable, Sendable {
        case wire
        case ach
    }

    // MARK: - Onramp Types

    struct BridgeOnrampStatusResponse: Codable, Equatable, Sendable {
        public let kycStatus: BridgeKycStatus
        public let kycLink: String?
        public let tosStatus: String?
        public let customerId: String?
        public let virtualAccount: BridgeVirtualAccount?

        public init(
            kycStatus: BridgeKycStatus,
            kycLink: String?,
            tosStatus: String?,
            customerId: String?,
            virtualAccount: BridgeVirtualAccount?
        ) {
            self.kycStatus = kycStatus
            self.kycLink = kycLink
            self.tosStatus = tosStatus
            self.customerId = customerId
            self.virtualAccount = virtualAccount
        }

        enum CodingKeys: String, CodingKey {
            case kycStatus = "kyc_status"
            case kycLink = "kyc_link"
            case tosStatus = "tos_status"
            case customerId = "customer_id"
            case virtualAccount = "virtual_account"
        }
    }

    struct BridgeVirtualAccount: Codable, Equatable, Sendable {
        public let id: UInt
        public let bridgeId: String
        public let status: String
        public let destination: BridgeDestination
        public let sourceDepositInstructions: BridgeDepositInstructions?

        public init(
            id: UInt,
            bridgeId: String,
            status: String,
            destination: BridgeDestination,
            sourceDepositInstructions: BridgeDepositInstructions?
        ) {
            self.id = id
            self.bridgeId = bridgeId
            self.status = status
            self.destination = destination
            self.sourceDepositInstructions = sourceDepositInstructions
        }

        enum CodingKeys: String, CodingKey {
            case id
            case bridgeId = "bridge_id"
            case status
            case destination
            case sourceDepositInstructions = "source_deposit_instructions"
        }
    }

    struct BridgeDestination: Codable, Equatable, Sendable {
        public let paymentRail: String
        public let currency: String
        public let address: String

        public init(paymentRail: String, currency: String, address: String) {
            self.paymentRail = paymentRail
            self.currency = currency
            self.address = address
        }

        enum CodingKeys: String, CodingKey {
            case paymentRail = "payment_rail"
            case currency
            case address
        }
    }

    struct BridgeDepositInstructions: Codable, Equatable, Sendable {
        public let currency: String?
        public let bankName: String?
        public let bankAddress: String?
        public let bankRoutingNumber: String?
        public let bankAccountNumber: String?
        public let bankBeneficiaryName: String?
        public let bankBeneficiaryAddress: String?
        public let paymentRails: [String]?

        public init(
            currency: String?,
            bankName: String?,
            bankAddress: String?,
            bankRoutingNumber: String?,
            bankAccountNumber: String?,
            bankBeneficiaryName: String?,
            bankBeneficiaryAddress: String?,
            paymentRails: [String]?
        ) {
            self.currency = currency
            self.bankName = bankName
            self.bankAddress = bankAddress
            self.bankRoutingNumber = bankRoutingNumber
            self.bankAccountNumber = bankAccountNumber
            self.bankBeneficiaryName = bankBeneficiaryName
            self.bankBeneficiaryAddress = bankBeneficiaryAddress
            self.paymentRails = paymentRails
        }

        enum CodingKeys: String, CodingKey {
            case currency
            case bankName = "bank_name"
            case bankAddress = "bank_address"
            case bankRoutingNumber = "bank_routing_number"
            case bankAccountNumber = "bank_account_number"
            case bankBeneficiaryName = "bank_beneficiary_name"
            case bankBeneficiaryAddress = "bank_beneficiary_address"
            case paymentRails = "payment_rails"
        }
    }

    struct BridgeOnrampInitiateResponse: Codable, Equatable, Sendable {
        public let virtualAccount: BridgeVirtualAccount
        public let sourceDepositInstructions: BridgeDepositInstructions?

        public init(
            virtualAccount: BridgeVirtualAccount,
            sourceDepositInstructions: BridgeDepositInstructions?
        ) {
            self.virtualAccount = virtualAccount
            self.sourceDepositInstructions = sourceDepositInstructions
        }

        enum CodingKeys: String, CodingKey {
            case virtualAccount = "virtual_account"
            case sourceDepositInstructions = "source_deposit_instructions"
        }
    }

    struct BridgeOnrampEvent: Codable, Equatable, Sendable {
        public let bridgeEventId: String
        public let bridgeDepositId: String?
        public let eventType: String
        public let amount: String?
        public let currency: String?
        public let sourcePaymentRail: String?
        public let destinationTxHash: String?

        public init(
            bridgeEventId: String,
            bridgeDepositId: String?,
            eventType: String,
            amount: String?,
            currency: String?,
            sourcePaymentRail: String?,
            destinationTxHash: String?
        ) {
            self.bridgeEventId = bridgeEventId
            self.bridgeDepositId = bridgeDepositId
            self.eventType = eventType
            self.amount = amount
            self.currency = currency
            self.sourcePaymentRail = sourcePaymentRail
            self.destinationTxHash = destinationTxHash
        }

        enum CodingKeys: String, CodingKey {
            case bridgeEventId = "bridge_event_id"
            case bridgeDepositId = "bridge_deposit_id"
            case eventType = "event_type"
            case amount
            case currency
            case sourcePaymentRail = "source_payment_rail"
            case destinationTxHash = "destination_tx_hash"
        }
    }

    struct BridgeOnrampActivityResponse: Codable, Equatable, Sendable {
        public let events: [BridgeOnrampEvent]

        public init(events: [BridgeOnrampEvent]) {
            self.events = events
        }
    }
}
