import VCard

extension PMNIBirthday {

    var formattedBirthday: String {
        let vCardBirthdayTextFormatter = DateFormatter.vCardBirthdayTextFormatter
        var birthday = getDate()
        if birthday.isEmpty {
            birthday = getText()
        }
        guard let date = vCardBirthdayTextFormatter.date(from: birthday) else { return birthday }
        let contactBirthdayFormatter = DateFormatter.contactBirthdayFormatter
        return contactBirthdayFormatter.string(from: date)
    }

}
