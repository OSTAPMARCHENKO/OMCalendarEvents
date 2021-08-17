//
//  EventManagerError.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

import EventKit

public
enum EventManagerError {

    case authorizationStatus(EKAuthorizationStatus)

    case accessStatus(Bool)

    case message(String)

    case error(Error)
}
