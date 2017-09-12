import Vapor
import Foundation

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

extension Date {
    public func timeUntilNow(fallbackAfter: Int? = nil, fallbackFormat: String? = nil) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .weekOfYear, .month, .day, .hour, .minute, .second],
            from: self, to: Date()
        )

        if let fallback = fallbackAfter {
            let formatString: () -> String = {
                let formatter = DateFormatter()
                let fallbackFormat = fallbackFormat ?? "mm/dd/yyyy"
                formatter.dateFormat = fallbackFormat
                return formatter.string(from: self)
            }

            let years = fallback / 365
            let months = fallback / 30
            let weeks = fallback / 7
            if years > 0 {
                if components.year ?? 0 >= years {
                    return formatString()
                }
            } else if months > 0 {
                if components.month ?? 0 >= months {
                    return formatString()
                }
            } else if weeks > 0 {
                if components.weekOfYear ?? 0 >= weeks {
                    return formatString()
                }
            } else {
                if components.day ?? 0 > fallback {
                    return formatString()
                }
            }
        }

        if let year = components.year {
            if year >= 2 {
                return "\(year) years ago"
            } else if year >= 1 {
                return "a year ago"
            }
        }

        if let month = components.month {
            if month >= 2 {
                return "\(month) months ago"
            } else if month >= 1 {
                return "a month ago"
            }
        }

        if let week = components.weekOfYear {
            if week >= 2 {
                return "\(week) weeks ago"
            } else if week >= 1 {
                return "a week ago"
            }
        }

        if let day = components.day {
            if day >= 2 {
                return "\(day) days ago"
            } else if day >= 1 {
                return "a day ago"
            }
        }

        if let hour = components.hour {
            if hour >= 2 {
                return "\(hour) hours ago"
            } else if hour >= 1 {
                return "an hour ago"
            }
        }

        if let minute = components.minute {
            if minute >= 2 {
                return "\(minute) minutes ago"
            } else if minute >= 1 {
                return "a minute ago"
            }
        }

        if let second = components.second, second >= 5 {
            return "\(second) seconds ago"
        }

        return "just now"
    }
}
