//
//  EventAddMethod.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

public enum EventAddMethod {
    case easy(_ event: EventModel)

    /// fromModal -  available ONLY for native
    case fromModal(_ event: EventModel?)
}
