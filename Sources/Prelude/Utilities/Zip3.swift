import Foundation

public func zip3<A, B, C>(
    _ seq1: [A],
    _ seq2: [B],
    _ seq3: [C]
) -> [(A, B, C)] {
    let minLength = min(seq1.count, seq2.count, seq3.count)
    return (0..<minLength).map { (seq1[$0], seq2[$0], seq3[$0]) }
}
