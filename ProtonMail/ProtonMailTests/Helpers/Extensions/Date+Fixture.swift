import Foundation

extension Date {

    static func fixture(_ stringDate: String, timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = timeZone

        guard let date = formatter.date(from: stringDate) else {
            fatalError("\(self) is not a date in test format (yyyy-MM-dd HH:mm:ss)")
        }

        return date
    }

}
