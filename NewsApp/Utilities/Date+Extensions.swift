import Foundation

extension String {
    func toFormattedDateString() -> String {
        guard let date = self.parseISO8601Date() else {
            return self
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    func toRelativeTimeString() -> String {
        guard let date = self.parseISO8601Date() else {
            return self
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func parseISO8601Date() -> Date? {
        let isoFormatterWithFractional = ISO8601DateFormatter()
        isoFormatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatterWithFractional.date(from: self) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: self)
    }
}
