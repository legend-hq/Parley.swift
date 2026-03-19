import Foundation

public enum Token: String, CaseIterable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case `1INCH`
    case AAVE
    case AAPLx
    case ABBVx
    case ABTx
    case AERO
    case AMDx
    case AMZNx
    case ANON
    case APPx
    case ATH
    case ARB
    case AVGOx
    case AZNx
    case BACx
    case BLUR
    case BNKR
    case BRETT
    case BSHIB
    case BTBTx
    case CAKE
    case cbBTC
    case cbETH
    case CLANKER
    case CMCSAx
    case COINx
    case COMP
    case CRASH
    case CRCLx
    case CRMx
    case CRV
    case CRWDx
    case CSCOx
    case CVXx
    case DAI
    case DEGEN
    case DHRx
    case DOT
    case EIGEN
    case ENA
    case ETH
    case EURC
    case EUL
    case ezETH
    case FRAX
    case GHO
    case GLDx
    case GMEx
    case GMX
    case GOOGLx
    case GSx
    case HIGHER
    case HONx
    case HOODx
    case HYPE
    case IBMx
    case ICP
    case IEMGx
    case INTCx
    case JNJx
    case JPMx
    case JUP
    case KAITO
    case KOx
    case LDO
    case LINK
    case LINx
    case LLYx
    case LUM
    case MAx
    case MCDx
    case METAx
    case MKR
    case MOG
    case MORPHO
    case MRKx
    case MRVLx
    case MSFTx
    case MSTRx
    case NFLXx
    case NVDAx
    case NVOx
    case OP
    case ORCLx
    case osETH
    case PEPx
    case PFEx
    case PGx
    case PLTRx
    case PMx
    case POL
    case PENDLE
    case PEPE
    case PRIME
    case QQQx
    case rETH
    case RPL
    case rsETH
    case SHIB
    case SNX
    case SPYx
    case STRCx
    case stETH
    case SYRUP
    case TBLLx
    case TOWNS
    case TOSHI
    case TQQQx
    case TSLAx
    case UNHx
    case UNI
    case USDC
    case USDe
    case USDH
    case USDT
    case uSOL
    case uXRP
    case VIRTUAL
    case VTIx
    case VTx
    case Vx
    case VVV
    case WBTC
    case weETH
    case WELL
    case WETH
    case WLD
    case WHYPE
    case WMTx
    case WPOL
    case wstETH
    case XAUt
    case XOMx
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
            case .WHYPE:
                "HYPE"
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
            case .USDH:
                URL(string: "https://nativemarkets.com")
            case .HYPE, .WHYPE:
                URL(string: "https://hyperfoundation.org")
            default:
                nil
        }
    }
}
