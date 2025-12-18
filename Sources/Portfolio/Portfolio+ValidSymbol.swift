import Foundation

extension Portfolio {
    /// Get a valid symbol to be used in the app because some token symbols are inconsistent across chains
    public static func validSymbol(_ symbol: String) -> String {
        if symbol == "wrsETH" {
            // wrsETH is the same token as rsETH but on a different network so
            // we overwrite the symbol
            return "rsETH"
        } else if symbol == "USD₮0" {
            // Tether decided to rename USDT on arbitrum only
            return "USDT"
        } else {
            return symbol
        }
    }
}
