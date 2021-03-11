extension DateFormatter {

    static var contactBirthdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Environment.locale
        return formatter
    }

}
