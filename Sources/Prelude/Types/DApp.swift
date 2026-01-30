import Foundation

public enum DApp: String, CaseIterable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case Aave
    case Across
    case BaseBridge
    case CircleBridge
    case Coinbase = "CoinbaseIcon"
    case Compound
    case Legend
    case Morpho
    case Stargate
    case Uniswap
    case ZeroEx = "0x"
    case ProjectX

    public var displayName: String {
        switch self {
            case .BaseBridge:
                "Base Bridge"
            case .CircleBridge:
                "Circle CCTP"
            case .Coinbase:
                "Coinbase"
            case .ZeroEx:
                "0x"
            default:
                rawValue
        }
    }

    public init?(from string: String) {
        // First try direct raw value match
        if let dapp = DApp(rawValue: string) {
            self = dapp
            return
        }

        // Handle special cases and aliases
        switch string.uppercased() {
            case "0X", "ZEROX", "ZERO_EX":
                self = .ZeroEx
            case "BASE_BRIDGE", "BASE BRIDGE", "BASEBRIDGE":
                self = .BaseBridge
            case "CIRCLE_BRIDGE", "CIRCLE BRIDGE", "CIRCLEBRIDGE", "CCTP", "CIRCLE_CCTP", "CCTP_V2":
                self = .CircleBridge
            case "COINBASEICON":
                self = .Coinbase
            case "UNISWAP_V3":
                self = .Uniswap
            default:
                // Try case-insensitive raw value match
                if let dapp = DApp.allCases.first(where: {
                    $0.rawValue.uppercased() == string.uppercased()
                }) {
                    self = dapp
                } else {
                    return nil
                }
        }
    }
}
