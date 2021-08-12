//
//  Completions.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 8/12/21.
//

import Foundation

public typealias EventsManagerError = (EventManagerError?) -> Void
public typealias EventsManagerEmptyCompletion = () -> Void
public typealias EventsManagerEventsCompletion = ([EventModel]) -> Void
