//  Created by Ostap Marchenko on 25.05.2022.
//

import Foundation

struct DateFormatters {
    static let generalTimeFormatter = DateFormatters.dateFormatterWith("dd-MM-yyyy HH:mm:ss")
    static let monthTimeFormatter  = DateFormatters.dateFormatterWith("MMM")
    static let dayTimeFormatter  = DateFormatters.dateFormatterWith("dd")
    static let compareTimeFormatter  = DateFormatters.dateFormatterWith("MM yyyy")


    static func defaultFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.locale = .current
        return dateFormatter
    }

    static func dateFormatterWith(_ format: String) -> DateFormatter {
        let dateFormatter = DateFormatters.defaultFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = .current
        return dateFormatter
    }
}

extension DateFormatter {
    func extract() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = self.dateFormat
        return formatter
    }
}
