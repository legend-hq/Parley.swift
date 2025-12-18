import Foundation

public func generateSecureRandomData(bytes count: Int) -> Data {
    var rng = SystemRandomNumberGenerator()
    return Data(
        (0..<count)
            .map { _ in
                UInt8.random(in: UInt8.min...UInt8.max, using: &rng)
            }
    )
}
