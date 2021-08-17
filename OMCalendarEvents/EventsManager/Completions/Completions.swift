//
//  Completions.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 8/12/21.
//

import Foundation
import EventKit

public typealias EventsManagerError = (EventManagerError?) -> Void
public typealias EventsManagerEmptyCompletion = () -> Void
public typealias EventsManagerStatusCompletion = (Bool) -> Void
public typealias EventsManagerTextCompletion = (String) -> Void
public typealias EventsManagerEventsCompletion = ([EventModel]) -> Void
public typealias AllNativeEventsCompletion = ([EKEvent]) -> Void
