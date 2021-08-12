//
//  EventAddMethod.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

enum EventAddMethod {
    case easy(event: EventModel)

    /// fromModal -  available ONLY for native
    case fromModal(event: EventModel?)
}
