//
//  CalendarType.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

import UIKit

public enum CalendarType {

    public enum Constants {
        public static let currentUserCalendar = "primary"
    }

    case native
    case google(clientID: String, on: UIViewController, calendarID: String = Constants.currentUserCalendar)
}
