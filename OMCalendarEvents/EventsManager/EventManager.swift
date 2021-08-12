//  Created by Ostap Marchenko on 7/30/21.

/// ****
/// Don't forget to add  Privacy --- Calendars Usage Description --- to application .plist file
/// ****

import UIKit
import EventKit
import EventKitUI

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

    /// add the new event to your calendar
    
    public func add(
        event: EventAddMethod,
        to calendar: CalendarType,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?
    ) {

        switch calendar {
        case .google(let controller, let clientID, let calendarID):
            self.googleManager = GoogleCalendarManager(on: controller, for: clientID, calendarID: calendarID)
            self.googleManager?.addEvent(event, onSuccess: onSuccess, onError: onError)

        case .native:
            self.nativeManager.addEvent(event, onSuccess: onSuccess, onError: onError)
        }
    }
}
