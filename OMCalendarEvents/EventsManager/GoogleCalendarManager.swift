//  Created by Ostap Marchenko on 7/30/21.

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

private extension EventModel {
    init(_ event: GTLRCalendar_Event) {
        self.init(
            start: event.start?.dateTime?.date ?? Date(),
            end: event.end?.dateTime?.date ?? Date(),
            title: event.summary ?? "",
            id: event.identifier,
            description: event.descriptionProperty
        )
    }
}

class GoogleCalendarManager {

    // MARK: Comments

    // 1.  Creates calendar service with current authentication

    // 2.  Have the service object set tickets to fetch consecutive pages
    //     of the feed so we do not need to manually fetch them

    // 3.  Have the service object set tickets to retry temporary error conditions automatically

    // 4.  Try to login user if user not loggedIn

    /// **********************************************************************

    private enum Constants {
        static let maxRetryInterval: TimeInterval = 15

        enum Error {
            static let authorizationFail: String = "\nGIDSignIn currentUser not authenticated\n"
            static let modalError: String = "\n MODAL EVENT CREATING NOT AVAILABLE FOR GOOGLE!\n"
            static let serviceError: String = "\nAdd event to google calendar error. CalendarService == NIL\n"
            static let listError: String = "\nGoogle events list error\n"
            static let cantFindEvent: String = "\nCan't find event in Google calendar\n"
        }

        enum Success {
            static let eventRemoved: String = "\nGoogle Calendar event removed status code - "
            static let eventAdded: String = "\nGoogle Calendar event added\n"
        }
    }

    /// (1)

    /// Required parameters
    private let controller: UIViewController
    private let clientID: String
    private let calendarID: String

    // MARK: Properties(Private)

    private lazy var calendarService: GTLRCalendarService? = {
        let service = GTLRCalendarService()

        // (2)

        service.shouldFetchNextPages = true

        // (3)

        service.isRetryEnabled = true
        service.maxRetryInterval = Constants.maxRetryInterval

        guard
            let currentUser = GIDSignIn.sharedInstance().currentUser,

            let authentication = currentUser.authentication else {
            return nil
        }

        service.authorizer = authentication.fetcherAuthorizer()
        return service
    }()

    private var signInService: GoogleSignInService?

    // MARK: Initializer

    init(on controller: UIViewController, for clientID: String, calendarID: String) {
        self.controller = controller
        self.clientID = clientID
        self.calendarID = calendarID
    }

    // MARK: Methods(Public)

    internal
    func addEvent(
        _ event: EventAddMethod,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: EventsManagerError?
    ) {

        getUser {
            switch event {
            case .easy(let event):
                self.addEventToCalendar(event, onSuccess: onSuccess, onError: onError)

            case .fromModal(let event):

                guard let event = event else {
                    onError?(.message(Constants.Error.modalError))
                    return
                }

                self.addEventToCalendar(event, onSuccess: onSuccess, onError: onError)
            }
        }

        onError: {
            onError?(.message(Constants.Error.authorizationFail))
        }
    }

    internal
    func removeEvent(
        _ event: EventModel,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: @escaping EventsManagerError
    ) {

        getUser { [weak self] in
            self?.getAllEvents(
                onSuccess: { events in

                    if let eventToRemove = events.first(
                        where: { $0.id == event.id || (
                            $0.startDate == event.startDate
                                && $0.endDate == event.endDate
                                && $0.title == event.title
                        )
                        }
                    ) {
                        self?.removeEvent(eventToRemove.id, onSuccess: onSuccess, onError: onError)
                    }
                    else {
                        onError(.message(Constants.Error.cantFindEvent))
                    }
                },

                onError: { error in
                    onError(error)
                }
            )
        }

        onError: {
            onError(.message(Constants.Error.authorizationFail))
        }
    }

    // MARK: Methods(Private)

    private func getUser(
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: @escaping EventsManagerEmptyCompletion
    ) {

        if let currentUser = GIDSignIn.sharedInstance().currentUser,

            currentUser.authentication != nil {
            onSuccess()
        }
        else {

            // (4)
            signInService = GoogleSignInService(controller, clientID)
            signInService?.onSignIn = { success in
                if success {
                    onSuccess()
                }
                else {
                    onError()
                }
            }
        }
    }

    // MARK: Methods(Private)

    internal
    func removeEvent(
        _ event: String?,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: @escaping EventsManagerError
    ) {

        guard let id = event else {
            onError(.message(Constants.Error.cantFindEvent))
            return
        }

        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarID, eventId: id)

        calendarService?.executeQuery(query, completionHandler: { ticket, _, error in
            if let error = error {
                onError(.error(error))
            }
            else {
                onSuccess("\(Constants.Success.eventRemoved) = \((ticket as GTLRServiceTicket).statusCode)")
            }
        }
        )
    }

    private func addEventToCalendar(
        _ event: EventModel,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: EventsManagerError?
    ) {

        guard let service = calendarService else {
            onError?(.message(Constants.Error.serviceError))
            return
        }

        let newEvent = generateEvent(from: event)
        
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: newEvent, calendarId: calendarID)
        service.executeQuery(query) { _, _, error in

            if let error = error {
                onError?(.error(error))
            }
            else {
                onSuccess(Constants.Success.eventAdded)
            }
        }
    }

    private func getAllEvents(
        onSuccess: @escaping EventsManagerEventsCompletion,
        onError: @escaping EventsManagerError
    ) {
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarID)
        calendarService?.executeQuery(query) { _, events, error in

            if let error = error {
                onError(.error(error))
            }
            else {
                guard
                    let events = events as? GTLRCalendar_Events,

                    let eventsList = events.items
                else {
                    onError(.message(Constants.Error.listError))
                    return
                }

                let mapped = eventsList.map({ EventModel($0) })
                onSuccess(mapped)
            }
        }
    }

    private func generateEvent(from event: EventModel) -> GTLRCalendar_Event {
        let newEvent: GTLRCalendar_Event = GTLRCalendar_Event()

        newEvent.start = buildDate(form: event.startDate)
        newEvent.end = buildDate(form: event.endDate)
        newEvent.reminders?.useDefault = 7

        /// event title
        newEvent.summary = event.title

        /// event description text
        /// support html strings
        newEvent.descriptionProperty = event.description

        return newEvent
    }

    // Helper to build date

    private func buildDate(form date: Date) -> GTLRCalendar_EventDateTime {
        let datetime = GTLRDateTime(date: date)
        let dateObject = GTLRCalendar_EventDateTime()
        dateObject.dateTime = datetime
        return dateObject
    }
}

final class GoogleSignInService: NSObject, GIDSignInDelegate {

    typealias LoginCompletion = (Bool) -> Void

    // MARK: Completions

    var onSignIn: LoginCompletion?

    // MARK: Properties(Private)

    private let clientID: String

    // MARK: Initializer

    init(_ controller: UIViewController, _ clientID: String) {
        self.clientID = clientID

        super.init()

        configure(on: controller)
    }

    // MARK: Methods(Private)

    private func configure( on controller: UIViewController) {
        GIDSignIn.sharedInstance().clientID = clientID
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeCalendar]
        GIDSignIn.sharedInstance().presentingViewController = controller
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.signOut()
        GIDSignIn.sharedInstance()?.signIn()
    }

    // MARK: Methods(Public)

    /// Delegate method
    func sign(_ signIn: GIDSignIn, didSignInFor user: GIDGoogleUser, withError error: Error) {
        onSignIn?(user.authentication?.accessToken != nil)
    }
}
