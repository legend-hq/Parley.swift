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

    // MARK: - Offramp Types

    struct BridgeOfframpStatusResponse: Codable, Equatable, Sendable {
        public let kycStatus: BridgeKycStatus
        public let kycLink: String?
        public let tosStatus: String?
        public let customerId: String?
        public let hasBankAccount: Bool
        public let bankAccounts: [BridgeExternalAccount]

        public init(
            kycStatus: BridgeKycStatus,
            kycLink: String?,
            tosStatus: String?,
            customerId: String?,
            hasBankAccount: Bool,
            bankAccounts: [BridgeExternalAccount]
        ) {
            self.kycStatus = kycStatus
            self.kycLink = kycLink
            self.tosStatus = tosStatus
            self.customerId = customerId
            self.hasBankAccount = hasBankAccount
            self.bankAccounts = bankAccounts
        }

        enum CodingKeys: String, CodingKey {
            case kycStatus = "kyc_status"
            case kycLink = "kyc_link"
            case tosStatus = "tos_status"
            case customerId = "customer_id"
            case hasBankAccount = "has_bank_account"
            case bankAccounts = "bank_accounts"
        }
    }

    struct BridgeExternalAccount: Codable, Equatable, Sendable {
        public let bridgeId: String
        public let bankName: String?
        public let accountName: String?
        public let accountOwnerName: String?
        public let last4: String?
        public let currency: String?
        public let accountType: String?
        public let active: Bool?
        public let beneficiaryAddressValid: Bool?

        public init(
            bridgeId: String,
            bankName: String?,
            accountName: String?,
            accountOwnerName: String?,
            last4: String?,
            currency: String?,
            accountType: String?,
            active: Bool?,
            beneficiaryAddressValid: Bool?
        ) {
            self.bridgeId = bridgeId
            self.bankName = bankName
            self.accountName = accountName
            self.accountOwnerName = accountOwnerName
            self.last4 = last4
            self.currency = currency
            self.accountType = accountType
            self.active = active
            self.beneficiaryAddressValid = beneficiaryAddressValid
        }

        public var displayLast4: String {
            if let last4 {
                return "••••\(last4)"
            }
            return "••••"
        }

        enum CodingKeys: String, CodingKey {
            case bridgeId = "bridge_id"
            case bankName = "bank_name"
            case accountName = "account_name"
            case accountOwnerName = "account_owner_name"
            case last4 = "last_4"
            case currency
            case accountType = "account_type"
            case active
            case beneficiaryAddressValid = "beneficiary_address_valid"
        }
    }

    struct BridgeLiquidationAddress: Codable, Equatable, Sendable {
        public let id: UInt
        public let bridgeId: String
        public let chain: String
        public let address: String
        public let destinationPaymentRail: String
        public let state: String

        public init(
            id: UInt,
            bridgeId: String,
            chain: String,
            address: String,
            destinationPaymentRail: String,
            state: String
        ) {
            self.id = id
            self.bridgeId = bridgeId
            self.chain = chain
            self.address = address
            self.destinationPaymentRail = destinationPaymentRail
            self.state = state
        }

        enum CodingKeys: String, CodingKey {
            case id
            case bridgeId = "bridge_id"
            case chain
            case address
            case destinationPaymentRail = "destination_payment_rail"
            case state
        }
    }

    struct BridgeCreateBankAccountRequest: Codable, Equatable, Sendable {
        public let bankName: String
        public let firstName: String
        public let lastName: String
        public let accountOwnerName: String
        public let accountNumber: String
        public let routingNumber: String
        public let checkingOrSavings: String
        public let address: BridgeBankAccountAddress

        public init(
            bankName: String,
            firstName: String,
            lastName: String,
            accountOwnerName: String,
            accountNumber: String,
            routingNumber: String,
            checkingOrSavings: String,
            address: BridgeBankAccountAddress
        ) {
            self.bankName = bankName
            self.firstName = firstName
            self.lastName = lastName
            self.accountOwnerName = accountOwnerName
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.checkingOrSavings = checkingOrSavings
            self.address = address
        }

        enum CodingKeys: String, CodingKey {
            case bankName = "bank_name"
            case firstName = "first_name"
            case lastName = "last_name"
            case accountOwnerName = "account_owner_name"
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
            case checkingOrSavings = "checking_or_savings"
            case address
        }
    }

    struct BridgeBankAccountAddress: Codable, Equatable, Sendable {
        public let streetLine1: String
        public let city: String
        public let state: String
        public let postalCode: String
        public let country: String

        public init(
            streetLine1: String,
            city: String,
            state: String,
            postalCode: String,
            country: String
        ) {
            self.streetLine1 = streetLine1
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }

        enum CodingKeys: String, CodingKey {
            case streetLine1 = "street_line_1"
            case city
            case state
            case postalCode = "postal_code"
            case country
        }
    }

    struct BridgeCreateBankAccountResponse: Codable, Equatable, Sendable {
        public let bankAccount: BridgeExternalAccount

        public init(bankAccount: BridgeExternalAccount) {
            self.bankAccount = bankAccount
        }

        enum CodingKeys: String, CodingKey {
            case bankAccount = "bank_account"
        }
    }

    struct BridgeOfframpInitiateRequest: Codable, Equatable, Sendable {
        public let bankAccountId: String?
        public let quarkWalletId: UInt?
        public let paymentRail: String

        public init(
            bankAccountId: String?,
            quarkWalletId: UInt?,
            paymentRail: String
        ) {
            self.bankAccountId = bankAccountId
            self.quarkWalletId = quarkWalletId
            self.paymentRail = paymentRail
        }

        enum CodingKeys: String, CodingKey {
            case bankAccountId = "bank_account_id"
            case quarkWalletId = "quark_wallet_id"
            case paymentRail = "payment_rail"
        }
    }

    struct BridgeOfframpBankAccount: Codable, Equatable, Sendable {
        public let bridgeId: String

        public init(bridgeId: String) {
            self.bridgeId = bridgeId
        }

        enum CodingKeys: String, CodingKey {
            case bridgeId = "bridge_id"
        }
    }

    struct BridgeOfframpInitiateResponse: Codable, Equatable, Sendable {
        public let liquidationAddress: BridgeLiquidationAddress
        public let sendToAddress: String
        public let paymentRail: String
        public let bankAccount: BridgeOfframpBankAccount

        public init(
            liquidationAddress: BridgeLiquidationAddress,
            sendToAddress: String,
            paymentRail: String,
            bankAccount: BridgeOfframpBankAccount
        ) {
            self.liquidationAddress = liquidationAddress
            self.sendToAddress = sendToAddress
            self.paymentRail = paymentRail
            self.bankAccount = bankAccount
        }

        enum CodingKeys: String, CodingKey {
            case liquidationAddress = "liquidation_address"
            case sendToAddress = "send_to_address"
            case paymentRail = "payment_rail"
            case bankAccount = "bank_account"
        }
    }

    struct BridgeOfframpQuoteRequest: Codable, Equatable, Sendable {
        public let amount: String
        public let paymentRail: String

        public init(amount: String, paymentRail: String) {
            self.amount = amount
            self.paymentRail = paymentRail
        }

        enum CodingKeys: String, CodingKey {
            case amount
            case paymentRail = "payment_rail"
        }
    }

    struct BridgeOfframpQuoteResponse: Codable, Equatable, Sendable {
        public let amount: String
        public let paymentRail: String
        public let feePercent: String
        public let feeAmount: String
        public let receiveAmount: String
        public let receiveCurrency: String
        public let estimatedArrival: String

        public init(
            amount: String,
            paymentRail: String,
            feePercent: String,
            feeAmount: String,
            receiveAmount: String,
            receiveCurrency: String,
            estimatedArrival: String
        ) {
            self.amount = amount
            self.paymentRail = paymentRail
            self.feePercent = feePercent
            self.feeAmount = feeAmount
            self.receiveAmount = receiveAmount
            self.receiveCurrency = receiveCurrency
            self.estimatedArrival = estimatedArrival
        }

        enum CodingKeys: String, CodingKey {
            case amount
            case paymentRail = "payment_rail"
            case feePercent = "fee_percent"
            case feeAmount = "fee_amount"
            case receiveAmount = "receive_amount"
            case receiveCurrency = "receive_currency"
            case estimatedArrival = "estimated_arrival"
        }
    }

    struct BridgeOfframpEvent: Codable, Equatable, Sendable {
        public let bridgeDrainId: String
        public let state: String
        public let amount: String?
        public let currency: String?
        public let depositTxHash: String?
        public let destinationTxHash: String?
        public let destinationPaymentRail: String?

        public init(
            bridgeDrainId: String,
            state: String,
            amount: String?,
            currency: String?,
            depositTxHash: String?,
            destinationTxHash: String?,
            destinationPaymentRail: String?
        ) {
            self.bridgeDrainId = bridgeDrainId
            self.state = state
            self.amount = amount
            self.currency = currency
            self.depositTxHash = depositTxHash
            self.destinationTxHash = destinationTxHash
            self.destinationPaymentRail = destinationPaymentRail
        }

        enum CodingKeys: String, CodingKey {
            case bridgeDrainId = "bridge_drain_id"
            case state
            case amount
            case currency
            case depositTxHash = "deposit_tx_hash"
            case destinationTxHash = "destination_tx_hash"
            case destinationPaymentRail = "destination_payment_rail"
        }
    }

    struct BridgeOfframpActivityResponse: Codable, Equatable, Sendable {
        public let events: [BridgeOfframpEvent]

        public init(events: [BridgeOfframpEvent]) {
            self.events = events
        }
    }
}
