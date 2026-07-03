import Foundation

enum JSONCoding {
    static func makeEncoder(
        outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys],
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = dateEncodingStrategy
        return encoder
    }

    static func makeDecoder(
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return decoder
    }

    static func encodePrettySorted<T: Encodable>(_ value: T) throws -> Data {
        try makeEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }
}
