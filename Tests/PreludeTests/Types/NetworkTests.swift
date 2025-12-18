import Eth
import Foundation
import Prelude
import Testing

struct NetworkTests {
    @Test
    func testExplorerUrl() {
        let network: Network = .ethereum
        let url = network.explorerUrl
        #expect(url == URL(string: "https://etherscan.io")!)
    }

    @Test
    func testExplorerUrlWithAddress() {
        let network: Network = .ethereum

        let url = network.explorerUrl(address: "0xd8da6bf26964af9d7eed9e03e53415d37aa96045")
        #expect(url == URL(string: "https://etherscan.io/address/0xd8da6bf26964af9d7eed9e03e53415d37aa96045")!)
    }

    @Test
    func testArrayFormatted() {
        let networks: [Network] = [.ethereum, .arbitrum, .base]
        #expect(networks.formatted() == "3 Networks")

        let oneNetwork: [Network] = [.ethereum]
        #expect(oneNetwork.formatted() == "Ethereum")
    }

    @Test
    func testSortedByPriority() {
        let networks: [Network] = [.arbitrum, .optimism, .base, .scrollSepolia]
        #expect(networks.sortedByPriority() == [.base, .arbitrum, .optimism, .scrollSepolia])
    }
}
