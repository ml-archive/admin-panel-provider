import Vapor

extension String {
    public static func random(_ length: Int = 64) -> String {
        var buffer = Array<UInt8>()
        buffer.reserveCapacity(length)

        for _ in 0..<length {
            var value = Int.random(min: 0, max: 61)

            if value < 10 { // 0-10
                value = value &+ 0x30
            } else if value < 36 { // A-Z
                value = value &+ 0x37
            } else { // a-z
                value = value &+ 0x3D
            }

            buffer.append(UInt8(truncatingBitPattern: value))
        }

        return String(bytes: buffer)
    }

    public var isLocalhost: Bool {
         return self == "0.0.0.0" || self == "127.0.0.1"
    }
}
