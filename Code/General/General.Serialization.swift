//  Created by Ivan Kh on 02.05.2023.

import Foundation

public protocol BinaryEncodable {
    @discardableResult func encode(to data: inout Data) -> Int
}

public protocol BinaryDecodable {
    init(from data: inout Data) throws
}

public typealias BinaryCodable = BinaryEncodable & BinaryDecodable

public extension BinaryEncodable {
    var data: Data {
        var result = Data()
        encode(to: &result)
        return result
    }
}

public extension Data {
    enum CodingError: Error {
        case outOfMemory
    }

    @discardableResult mutating func encode<T: Numeric>(_ value: T) -> Int {
        withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) in
            append(UnsafeBufferPointer(start: ptr, count: 1))
        }

        return MemoryLayout<T>.size
    }

    @discardableResult private func decode<T>(_ type: T.Type, count: inout Int)
    throws -> T where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        let valueCount = MemoryLayout.size(ofValue: value)

        guard valueCount <= self.count else { throw CodingError.outOfMemory }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )

        count += valueCount
        return value
    }

    @discardableResult mutating func pop<T>(_ type: T.Type)
    throws -> T where T: ExpressibleByIntegerLiteral {
        var count = 0
        let result = try decode(type, count: &count)

        self = self[(startIndex + count)...]
        return result
    }
}

extension CGRect: BinaryCodable {
    public init(from data: inout Data) throws {
        self.init(origin: try .init(from: &data),
                  size: try .init(from: &data))
    }

    public func encode(to data: inout Data) -> Int {
        origin.encode(to: &data) + size.encode(to: &data)
    }
}

extension CGPoint: BinaryCodable {
    public init(from data: inout Data) throws {
        self.init(x: try data.pop(CGFloat.self),
                  y: try data.pop(CGFloat.self))
    }

    public func encode(to data: inout Data) -> Int {
        data.encode(x) + data.encode(y)
    }
}

extension CGSize: BinaryCodable {
    public init(from data: inout Data) throws {
        self.init(width: try data.pop(CGFloat.self),
                  height: try data.pop(CGFloat.self))
    }

    public func encode(to data: inout Data) -> Int {
        data.encode(width) + data.encode(height)
    }
}
