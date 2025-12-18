import Charter
import Foundation
import Portfolio
import Prelude
import SwiftNumber
import Tradewinds

@_expose(wasm, "alloc") @_cdecl("alloc")
public func alloc(_ size: Int32) -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer.allocate(
        byteCount: Int(size),
        alignment: MemoryLayout<UInt8>.alignment
    )
}

@_expose(wasm, "dealloc") @_cdecl("dealloc")
public func dealloc(_ ptr: UnsafeMutableRawPointer, _: Int32) {
    ptr.deallocate()
}

// MARK: - Version and Info Functions

@_expose(wasm, "version") @_cdecl("version")
public func version() -> UInt64 {
    let version = Charter.version
    let data = version.data(using: .utf8)!
    let ptr = alloc(Int32(data.count))
    data.copyBytes(to: ptr.assumingMemoryBound(to: UInt8.self), count: data.count)

    let ptrInt = UInt32(UInt(bitPattern: ptr))
    let len = UInt32(data.count)
    return UInt64(ptrInt) | (UInt64(len) << 32)
}

@_expose(wasm, "name") @_cdecl("name")
public func name() -> UInt64 {
    let name = "Parley"
    let data = name.data(using: .utf8)!
    let ptr = alloc(Int32(data.count))
    data.copyBytes(to: ptr.assumingMemoryBound(to: UInt8.self), count: data.count)

    let ptrInt = UInt32(UInt(bitPattern: ptr))
    let len = UInt32(data.count)
    return UInt64(ptrInt) | (UInt64(len) << 32)
}

@_expose(wasm, "atlas") @_cdecl("atlas")
public func atlas() -> UInt64 {
    let name = "Atlas"
    let data = name.data(using: .utf8)!
    let ptr = alloc(Int32(data.count))
    data.copyBytes(to: ptr.assumingMemoryBound(to: UInt8.self), count: data.count)

    let ptrInt = UInt32(UInt(bitPattern: ptr))
    let len = UInt32(data.count)
    return UInt64(ptrInt) | (UInt64(len) << 32)
}

struct APIResult<T: Codable>: Codable {
    let success: Bool
    let result: T?
    let error: String?
    let logs: [String]?
}

func processJSON<Input: Codable, Output: Codable>(
    _ ptr: Int32,
    _ len: Int32,
    logger: Charter.Logger,
    transform: (Input) throws -> Output
) -> UInt64 {
    let raw = UnsafeRawPointer(bitPattern: UInt(ptr))!
    let data = Data(bytes: raw, count: Int(len))

    do {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        let input = try jsonDecoder.decode(Input.self, from: data)
        let output = try transform(input)
        let result = APIResult(success: true, result: output, error: nil, logs: logger.logs)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let outData = try jsonEncoder.encode(result)

        let outPtr = alloc(Int32(outData.count))
        outData.copyBytes(to: outPtr.assumingMemoryBound(to: UInt8.self), count: outData.count)

        let ptr = UInt32(UInt(bitPattern: outPtr))
        let len = UInt32(outData.count)
        return UInt64(ptr) | (UInt64(len) << 32)
    } catch let decodingError as DecodingError {
        // More detailed error message for decoding errors
        let errorMessage: String
        switch decodingError {
            case .keyNotFound(let key, let context):
                errorMessage =
                    "Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMessage =
                    "Type mismatch for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMessage =
                    "Value not found for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMessage =
                    "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            @unknown default:
                errorMessage = decodingError.localizedDescription
        }

        let result = APIResult<Output>(
            success: false,
            result: nil,
            error: errorMessage,
            logs: logger.logs
        )
        let errorData = try! JSONEncoder().encode(result)
        let outPtr = alloc(Int32(errorData.count))
        errorData.copyBytes(to: outPtr.assumingMemoryBound(to: UInt8.self), count: errorData.count)

        let ptr = UInt32(UInt(bitPattern: outPtr))
        let len = UInt32(errorData.count)
        return UInt64(ptr) | (UInt64(len) << 32)
    } catch {
        let result = APIResult<Output>(
            success: false,
            result: nil,
            error: error.localizedDescription,
            logs: logger.logs
        )
        let errorData = try! JSONEncoder().encode(result)
        let outPtr = alloc(Int32(errorData.count))
        errorData.copyBytes(to: outPtr.assumingMemoryBound(to: UInt8.self), count: errorData.count)

        let ptr = UInt32(UInt(bitPattern: outPtr))
        let len = UInt32(errorData.count)
        return UInt64(ptr) | (UInt64(len) << 32)
    }
}

struct FolioFromPortfoliosRequest: Codable {
    let portfolios: [Portfolio]
    let quote: Quote
    let bridgeHints: [LegendModel.BridgeHint]
    let prices: [String: Value]
    let nonceSecrets: [NonceSecret]

    enum CodingKeys: String, CodingKey {
        case portfolios
        case quote
        case bridgeHints = "bridge_hints"
        case prices
        case nonceSecrets = "nonce_secrets"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        portfolios = try container.decode([Portfolio].self, forKey: .portfolios)
        quote = try container.decode(Quote.self, forKey: .quote)
        bridgeHints = try container.decode([LegendModel.BridgeHint].self, forKey: .bridgeHints)
        nonceSecrets = try container.decode([NonceSecret].self, forKey: .nonceSecrets)

        // Decode prices: convert [String: String] to [String: Value]
        let pricesDict = try container.decode([String: String].self, forKey: .prices)
        var decodedPrices: [String: Value] = [:]
        for (key, stringValue) in pricesDict {
            decodedPrices[key] = try Value(scientificString: stringValue)
        }
        prices = decodedPrices
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(portfolios, forKey: .portfolios)
        try container.encode(quote, forKey: .quote)
        try container.encode(bridgeHints, forKey: .bridgeHints)
        try container.encode(nonceSecrets, forKey: .nonceSecrets)

        // Encode prices: convert [String: Value] to [String: String]
        var encodedPrices: [String: String] = [:]
        for (key, value) in prices {
            encodedPrices[key] = value.scientific
        }
        try container.encode(encodedPrices, forKey: .prices)
    }
}

struct ChartRequest: Codable {
    let version: String
    let intent: Charter.QuarkIntent
    let folio: Folio
    let debug: Bool?

    enum CodingKeys: String, CodingKey {
        case version
        case intent
        case folio
        case debug
    }
}

struct ChartResponse: Codable {
    let chart: Charter.Chart?
    let error: Charter.CharterError?
    let dots: [String: String]?
    let max: Number?
}

struct FolioResponse: Codable {
    let folio: Folio?
}

@_expose(wasm, "chart") @_cdecl("chart")
public func chart(_ ptr: Int32, _ len: Int32) -> UInt64 {
    let logger = Charter.Logger()

    return processJSON(ptr, len, logger: logger) { (request: ChartRequest) in
        var max: Number? = nil

        if request.debug == true {
            // Use extended API to get debug information
            let (result, flowResult, routes, resources, target) = Charter.chartExtended(
                intent: request.intent,
                folio: request.folio,
                logger: logger
            )

            // Generate visualization DOT strings if we have the necessary data
            // This is useful for both success and failure cases
            var dots: [String: String] = [:]
            if let routes = routes, let resources = resources, let target = target {
                // Setup graph (no flows)
                dots["setup"] = Tradewinds.generateDot(
                    version: Charter.version,
                    routes: routes,
                    resources: resources,
                    flows: nil,
                    target: target
                )

                // Solution graph (with flows if available)
                if let flows = flowResult?.flows {
                    dots["solution"] = Tradewinds.generateDot(
                        version: Charter.version,
                        routes: routes,
                        resources: resources,
                        flows: flows,
                        target: target
                    )
                }

                // Max flow graph
                if case .success((flows: let maxFlows, maxFlow: let maxFlow)) =
                    Charter.maxFlowExtended(
                        intent: request.intent.type,
                        folio: request.folio,
                        logger: logger
                    )
                {
                    dots["max"] = Tradewinds.generateDot(
                        version: Charter.version,
                        routes: routes,
                        resources: resources,
                        flows: maxFlows,
                        target: target
                    )

                    max = maxFlow
                }
            }

            switch result {
                case .success(let chart):
                    return ChartResponse(chart: chart, error: nil, dots: dots, max: max)
                case .failure(let error):
                    // Return dots even on failure - they can help debug why it failed
                    return ChartResponse(chart: nil, error: error, dots: dots, max: max)
            }
        } else {
            // Normal flow without debug
            let result = Charter.chart(
                intent: request.intent,
                folio: request.folio
            )

            switch result {
                case .success(let chart):
                    return ChartResponse(chart: chart, error: nil, dots: nil, max: nil)
                case .failure(let error):
                    return ChartResponse(chart: nil, error: error, dots: nil, max: nil)
            }
        }
    }
}

@_expose(wasm, "folioFromPortfolios") @_cdecl("folioFromPortfolios")
public func folioFromPortfolios(_ ptr: Int32, _ len: Int32) -> UInt64 {
    let logger = Charter.Logger()

    return processJSON(ptr, len, logger: logger) { (request: FolioFromPortfoliosRequest) in
        let folio = request.portfolios.toFolio(
            quote: request.quote,
            bridgeHints: request.bridgeHints,
            prices: request.prices,
            nonceSecrets: request.nonceSecrets
        )

        return FolioResponse(folio: folio)
    }
}
