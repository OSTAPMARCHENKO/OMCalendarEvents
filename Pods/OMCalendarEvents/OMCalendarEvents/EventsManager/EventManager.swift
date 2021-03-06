//  Created by Ostap Marchenko on 7/30/21.

/// ****
/// Don't forget to add  Privacy --- Calendars Usage Description --- to application .plist file
/// ****

import UIKit
import EventKit
import EventKitUI

public typealias EventsManagerError = (EventManagerError?) -> Void
public typealias EventsManagerEmptyCompletion = () -> Void
public typealias EventsManagerEventsCompletion = ([EventModel]) -> Void

public class EventsCalendarManager {

    // MARK: Completions

    var onError: EventsManagerError?
    var onSuccess: EventsManagerEmptyCompletion?

    // MARK: Properties(Private)

    private lazy var eventStore: EKEventStore = {
        EKEventStore()
    }()

    private lazy var nativeManager: NativeEventManager = {
        NativeEventManager()
    }()

    private var googleManager: GoogleCalendarManager?

    // MARK: Initialization
    
    public init() { }

    // MARK: Public(Methods)

    /// by default manager will show modal screen
    /// add event to eventKit(native calendar)

    public func add(
        event: EventAddMethod,
        to calendar: CalendarType,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?
    ) {

        switch calendar {
        case .google(let controller, let clientID, let calendarID):
            self.googleManager = GoogleCalendarManager(on: controller, for: clientID, calendarID: calendarID)
            self.addEventGoogleCalendar(event, onSuccess: onSuccess, onError: onError)

        case .native:
            self.nativeManager.addEvent(event, onSuccess: onSuccess, onError: onError)
        }
    }

    // MARK: Mthods(Private)
    
    private func addEventGoogleCalendar(
        _ event: EventAddMethod,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?) {

        googleManager?.addEvent(event, onSuccess: onSuccess, onError: onError)
    }
}
