//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

struct Place: ElasticObject, Codable {
    var placeId: String
    var status: Status

    var name: String
    var names: [String]
    var tags: [Tag]

    var phone: String?
    var website: String?
    var description: String?

    var menu: Menu?
    var price: Price?
    var counts: Counts?

    var location: Location

    var hours: [Hour]
    var images: [Image]
    var areas: [Area]

    var createdMillis: Int?
    var updatedMillis: Int?

    var ranking: Double?

    struct Status: Codable {
        var type: StatusType
        var moved: Moved?
        var updatedMillis: Int?

        enum StatusType: String, Codable {
            case open
            case renovation
            case closed
            case moved
            case other

            /// Defensive Decoding
            init(from decoder: Decoder) throws {
                switch try decoder.singleValueContainer().decode(String.self) {
                case "open": self = .open
                case "renovation": self = .renovation
                case "closed": self = .closed
                case "moved": self = .moved
                default: self = .other
                }
            }
        }

        struct Moved: Codable {
            var placeId: String
        }
    }

    struct Menu: Codable {
        var url: String?
    }

    struct Price: Codable {
        var perPax: Double?
    }

    struct Counts: Codable {
        var article: Article?
        var instagram: Instagram?

        struct Article: Codable {
            var profile: Int
            var single: Int
            var list: Int
            var total: Int
        }

        struct Instagram: Codable {
            var profile: Int
            var total: Int
        }
    }
}

struct Area: ElasticObject, Codable {
    var areaId: String

    var type: AreaType
    var name: String
    var names: [String]?

    var website: String?
    var description: String?

    var images: [Image]?
    var hour: [Hour]?
    var counts: Counts?

    var location: Location

    var updatedMillis: Int?
    var createdMillis: Int?

    enum AreaType: String, Codable {
        case City
        case Region
        case Cluster
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "City": self = .City
            case "Region": self = .Region
            case "Cluster": self = .Cluster
            default: self = .Other
            }
        }
    }

    struct Counts: Codable {
        var total: Int?
    }
}

struct Landmark: ElasticObject, Codable {
    var landmarkId: String

    var type: LandmarkType
    var name: String
    var location: Location

    var updatedMillis: Int?
    var createdMillis: Int?

    enum LandmarkType: String, Codable {
        case train
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "train": self = .train
            default: self = .other
            }
        }
    }
}

struct Tag: ElasticObject, Codable {
    var tagId: String
    var name: String
    var type: TagType

    var names: [String]?
    var createdMillis: Int?
    var updatedMillis: Int?

    enum TagType: String, Codable {
        case Food
        case Cuisine
        case Establishment
        case Amenities
        case Timing
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "Food": self = .Food
            case "Cuisine": self = .Cuisine
            case "Establishment": self = .Establishment
            case "Amenities": self = .Amenities
            case "Timing": self = .Timing
            default: self = .Other
            }
        }
    }
}

struct Location: Codable {
    var address: String?
    var street: String?
    var unitNumber: String?
    var neighbourhood: String?

    var city: String?
    var country: String?
    var postcode: String?

    var latLng: String?
    var polygon: Polygon?

    var landmarks: [Landmark]

    struct Polygon: Codable {
        var points: [String]
    }
}

struct Hour: Codable {
    var day: Day
    var open: String
    var close: String

    enum Day: String, Codable {
        case mon
        case tue
        case wed
        case thu
        case fri
        case sat
        case sun
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "mon": self = .mon
            case "tue": self = .tue
            case "wed": self = .wed
            case "thu": self = .thu
            case "fri": self = .fri
            case "sat": self = .sat
            case "sun": self = .sun
            default: self = .other
            }
        }
    }

    enum IsOpen {
        case open
        case opening
        case closed
        case closing
        case none
    }
}

extension Hour {
    private static let machineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private static let humanFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()

    var timeRange: String {
        return "\(Hour.parse(time: open)) - \(Hour.parse(time: close))"
    }

    static func timeAs(int time: String?) -> Int? {
        if let time = time {
            let split = time.split(separator: ":")
            if let hour = split.get(0), let min = split.get(1) {
                if let h = Int(hour), let m = Int(min) {
                    return h * 60 + m
                }
            }
        }
        return nil
    }

    func isBetween(date: Date, opening: Int = 0, closing: Int = 0) -> Bool {
        let now = Hour.timeAs(int: Hour.machineFormatter.string(from: date))!

        if let open = Hour.timeAs(int: self.open), let close = Hour.timeAs(int: self.close) {
            if (close < open) {
                return open - opening <= now && now + closing <= 2400
            }
            return open - opening <= now && now + closing <= close
        }
        return false
    }

    private static func parse(time: String) -> String {
        // 24:00 problem
        if (time == "24:00" || time == "23:59") {
            return "Midnight"
        }
        let date = machineFormatter.date(from: time)
        return humanFormatter.string(from: date!)
    }
}

extension Hour.Day {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var text: String {
        switch self {
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
        case .other: return "Day"
        }
    }

    static var today: Hour.Day {
        switch Calendar.current.component(.weekday, from: Date()) {
        case 1: return .mon
        case 2: return .tue
        case 3: return .wed
        case 4: return .thu
        case 5: return .fri
        case 6: return .sat
        case 7: return .sun
        default: return .other
        }
    }

    static func add(days: Int = 0) -> Hour.Day {
        if let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
            switch Calendar.current.component(.weekday, from: date) {
            case 1: return .mon
            case 2: return .tue
            case 3: return .wed
            case 4: return .thu
            case 5: return .fri
            case 6: return .sat
            case 7: return .sun
            default: return .other
            }
        }
        return .other
    }

    func isToday(day: Hour.Day) -> Bool {
        return day == Hour.Day.today
    }
}

extension Hour {
    class Grouped {
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            return formatter
        }()

        let hours: [Hour]
        let dayHours: [Hour.Day: String]

        init(hours: [Hour]) {
            self.hours = hours

            var dayHours = [Hour.Day: String]()
            for hour in hours.sorted(by: { $0.open < $1.open }) {
                if let timeRange = dayHours[hour.day] {
                    dayHours[hour.day] = timeRange + ", " + hour.timeRange
                } else {
                    dayHours[hour.day] = hour.timeRange
                }
            }
            self.dayHours = dayHours
        }

        subscript(day: Hour.Day) -> String {
            get {
                return dayHours[day] ?? "Closed"
            }
        }

        func isOpen(opening: Int = 30) -> Hour.IsOpen {
            return hours.isOpen(opening: opening)
        }

        var todayDayTimeRange: String {
            let dayInWeek = Grouped.dateFormatter.string(from: Date())
            return dayInWeek.capitalized + ": " + self[Hour.Day.today]
        }
    }
}

extension Array where Element == Hour {
    func isOpen(opening: Int = 30) -> Hour.IsOpen {
        if (self.isEmpty) {
            return .none
        }

        let date = Date()
        let currentDay = Hour.Day.today
        let currentHours = self.filter({ $0.day == currentDay })

        for hour in currentHours {
            if hour.isBetween(date: date) {
                if hour.isBetween(date: date, closing: 30) {
                    return .closing
                }
                return .open
            } else if hour.isBetween(date: date, opening: 30) {
                return .opening
            }
        }

        return .closed
    }

    var grouped: Hour.Grouped {
        return Hour.Grouped(hours: self)
    }
}

protocol ElasticObject: Codable {
//    var dataType: String { get }
//    var createdMillis: Int { get }
//    var updatedMillis: Int { get }
}