import Foundation

public enum Token: String, CaseIterable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case `1INCH`
    case AAVE
    case AERO
    case ANON
    case ATH
    case ARB
    case BLUR
    case BNKR
    case BRETT
    case BSHIB
    case CAKE
    case cbBTC
    case cbETH
    case CLANKER
    case COMP
    case CRASH
    case CRV
    case DAI
    case DEGEN
    case DOT
    case EIGEN
    case ENA
    case ETH
    case EURC
    case EUL
    case ezETH
    case FRAX
    case GHO
    case GMX
    case HIGHER
    case ICP
    case JUP
    case KAITO
    case LDO
    case LINK
    case LUM
    case MKR
    case MOG
    case MORPHO
    case OP
    case osETH
    case POL
    case PENDLE
    case PEPE
    case PRIME
    case rETH
    case RPL
    case rsETH
    case SHIB
    case SNX
    case stETH
    case SYRUP
    case TOWNS
    case TOSHI
    case UNI
    case USDC
    case USDe
    case USDT
    case uSOL
    case uXRP
    case VIRTUAL
    case VVV
    case WBTC
    case weETH
    case WELL
    case WETH
    case WLD
    case WPOL
    case wstETH
    case XAUt
    case ZORA
    case ZRO
    case UNKNOWN
}

public extension Token {
    /// Create a `Token` from a string. `UNKNOWN` is returned
    /// if the token symbol is not supported
    init(_ string: String) {
        if let token = Token.allCases.first(where: { $0.rawValue.equalIgnoringCase(string) }) {
            self = token
        } else {
            self = .UNKNOWN
        }
    }

    /// Get the appropriate underlying string for a `Token`
    func formatted() -> String {
        switch self {
            case .WETH:
                "ETH"
            case .wstETH:
                "stETH"
            case .WPOL:
                "POL"
            default:
                rawValue
        }
    }

    /// The website associated with the given token
    var website: URL? {
        switch self {
            case .ETH, .WETH:
                URL(string: "https://ethereum.org")
            case .POL, .WPOL:
                URL(string: "https://polygon.technology")
            case .USDC:
                URL(string: "https://www.circle.com/en/usdc")
            default:
                nil
        }
    }
}
