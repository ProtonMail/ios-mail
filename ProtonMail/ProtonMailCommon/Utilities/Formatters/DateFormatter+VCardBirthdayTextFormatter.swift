extension DateFormatter {

    static var vCardBirthdayTextFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }

}
