public struct PortfolioResponse: Codable, Equatable {
    public let data: PortfolioWrapper

    public struct PortfolioWrapper: Codable, Equatable {
        public let portfolios: [Portfolio]
    }

    public init(data: PortfolioWrapper) {
        self.data = data
    }
}
