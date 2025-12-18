import Foundation

/// Color identifiers that mirror the LegendApp asset catalog.
/// Convert to SwiftUI.Color in the app layer via `Color(legendColor.rawValue)`.
public enum LegendColor: String, CaseIterable, Sendable, Hashable {
    // MARK: - Actions

    case approve
    case borrow
    case claim
    case liquidation
    case long
    case short
    case supply
    case trade
    case transfer

    // MARK: - Button Fill

    case buttonEmphasized
    case buttonNeutral
    case buttonNeutralDisabled
    case buttonTinted
    case buttonTintedDisabled

    // MARK: - Button Label

    case disabledPrimary
    case disabledSecondary
    case emphasizedPrimary
    case emphasizedSecondary
    case neutralPrimary
    case neutralSecondary
    case tintedPrimary
    case tintedSecondary

    // MARK: - Containers

    case containerBlue
    case containerGold
    case containerGreen
    case containerNeutral
    case containerPurple
    case containerRed

    // MARK: - Data

    case dataNeutral1
    case dataNeutral2

    // MARK: - Icons

    case icon1
    case icon2
    case icon3
    case navIconActive
    case navIconInactive

    // MARK: - Primitive: Blue

    case blue10
    case blue30
    case blue50
    case blue70
    case blue90

    // MARK: - Primitive: Fuchsia

    case fuchsia10
    case fuchsia30
    case fuchsia50
    case fuchsia70
    case fuchsia90

    // MARK: - Primitive: Gold

    case gold10
    case gold30
    case gold50
    case gold70
    case gold90

    // MARK: - Primitive: Green

    case green10
    case green30
    case green50
    case green70
    case green90

    // MARK: - Primitive: Neutral

    case neutral00
    case neutral05
    case neutral10
    case neutral15
    case neutral20
    case neutral30
    case neutral40
    case neutral50
    case neutral60
    case neutral70
    case neutral80
    case neutral85
    case neutral90
    case neutral95
    case neutral100

    // MARK: - Primitive: Purple

    case purple10
    case purple30
    case purple50
    case purple70
    case purple90

    // MARK: - Primitive: Red

    case red10
    case red30
    case red50
    case red70
    case red90

    // MARK: - Text

    case buttonTextEmphasized
    case buttonTextEmphasizedSecondary
    case buttonTextNeutral
    case buttonTextNeutralDisabled
    case buttonTextTinted
    case buttonTextTintedDisabled
    case text1
    case text2
    case text3

    // MARK: - Tokens

    case token1INCH = "1INCH"
    case tokenAAVE = "AAVE"
    case tokenAERO = "AERO"
    case tokenANON = "ANON"
    case tokenARB = "ARB"
    case tokenATH = "ATH"
    case tokenBLUR = "BLUR"
    case tokenBNKR = "BNKR"
    case tokenBRETT = "BRETT"
    case tokenBSHIB = "BSHIB"
    case tokenCAKE = "CAKE"
    case tokenCbBTC = "cbBTC"
    case tokenCbETH = "cbETH"
    case tokenCLANKER = "CLANKER"
    case tokenCOMP = "COMP"
    case tokenCRASH = "CRASH"
    case tokenCRV = "CRV"
    case tokenDAI = "DAI"
    case tokenDEGEN = "DEGEN"
    case tokenDOT = "DOT"
    case tokenEIGEN = "EIGEN"
    case tokenENA = "ENA"
    case tokenETH = "ETH"
    case tokenEUL = "EUL"
    case tokenEURC = "EURC"
    case tokenEzETH = "ezETH"
    case tokenFRAX = "FRAX"
    case tokenGHO = "GHO"
    case tokenGMX = "GMX"
    case tokenHIGHER = "HIGHER"
    case tokenICP = "ICP"
    case tokenJUP = "JUP"
    case tokenKAITO = "KAITO"
    case tokenLDO = "LDO"
    case tokenLINK = "LINK"
    case tokenLUM = "LUM"
    case tokenMKR = "MKR"
    case tokenMOG = "MOG"
    case tokenMORPHO = "MORPHO"
    case tokenOP = "OP"
    case tokenOsETH = "osETH"
    case tokenPENDLE = "PENDLE"
    case tokenPEPE = "PEPE"
    case tokenPOL = "POL"
    case tokenPRIME = "PRIME"
    case tokenREth = "rETH"
    case tokenRPL = "RPL"
    case tokenRsETH = "rsETH"
    case tokenSHIB = "SHIB"
    case tokenSNX = "SNX"
    case tokenStETH = "stETH"
    case tokenSUSDe = "sUSDe"
    case tokenSYRUP = "SYRUP"
    case tokenTOSHI = "TOSHI"
    case tokenTOWNS = "TOWNS"
    case tokenUNI = "UNI"
    case tokenUSDC = "USDC"
    case tokenUSDe = "USDe"
    case tokenUSDT = "USDT"
    case tokenUSOL = "uSOL"
    case tokenUXRP = "uXRP"
    case tokenVIRTUAL = "VIRTUAL"
    case tokenVVV = "VVV"
    case tokenWBTC = "WBTC"
    case tokenWeETH = "weETH"
    case tokenWELL = "WELL"
    case tokenWLD = "WLD"
    case tokenXAUT = "XAUT"
    case tokenZORA = "ZORA"
    case tokenZRO = "ZRO"

    // MARK: - UI

    case activeOverlay
    case background
    case border
    case uiColor = "Color"
    case foreground
    case scrim

    // MARK: - Validation

    case negative
    case positive
    case validationNeutral = "neutral"
}
