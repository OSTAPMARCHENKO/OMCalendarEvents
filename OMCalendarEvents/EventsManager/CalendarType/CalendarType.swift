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
    case google(on: UIViewController, clientID: String, calendarID: String = Constants.currentUserCalendar)
}
