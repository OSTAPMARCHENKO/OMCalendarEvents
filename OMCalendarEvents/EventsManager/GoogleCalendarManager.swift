//  Created by Ostap Marchenko on 7/30/21.

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

/// GOOGLE CALENDAR  INTEGRATION

/// 1. - https://console.developers.google.com/ - create new project with current app Bundle ID

/// 2. - Go to dashboard, click Enable APIS AND SERVICES, choose calendar API service and enable it

/// 3. - Choose credentials from the side menu and click CREATE CREDENTIALS Link from top of the page and add OAuth Client ID

/// 4. - Go to the Firebase console, ADD new project with exiting app

/// 5. -  Add firebase google plist to current app

/// 6. ATTENTION!!! ADD to your signIn method this options, if application using GoogleSignIn
///   *********
///   GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/calendar", "https://www.googleapis.com/auth/calendar.events"]
///   *********
///   SCOPES options are REQUIRED!!!
///   Without them, you will not have access to the  calendar

final
open class GoogleCalendarManager {

    // MARK: Comments

    // 1.  Creates calendar service with current authentication

    // 2.  Have the service object set tickets to fetch consecutive pages
    //     of the feed so we do not need to manually fetch them

    // 3.  Have the service object set tickets to retry temporary error conditions automatically

    // 4.  Try to login user if user not loggedIn

    /// **************************** ---------------- ******************  ------------- *********************

    private enum Constants {
        static let maxRetryInterval: TimeInterval = 15

        enum Error {
            static let authorizationFail: String = "\n\n=== GIDSignIn currentUser not authenticated === \n\n"
            static let modalError: String = "\n\n=== MODAL EVENT CREATING NOT AVAILABLE FOR GOOGLE! === \n\n"
            static let serviceError: String = "\n\n=== Add event to google calendar error. CalendarService is NIL === \n\n"
        }
    }

    /// (1)

    /// required options
    private let controller: UIViewController!
    private let clientID: String!
    private let calendarID: String!

    // MARK: Properties(Private)

    private lazy var calendarService: GTLRCalendarService? = {
        let service = GTLRCalendarService()

        // (2)

        service.shouldFetchNextPages = true

        // (3)

        service.isRetryEnabled = true
        service.maxRetryInterval = Constants.maxRetryInterval

        guard let currentUser = GIDSignIn.sharedInstance().currentUser,
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

    public func addEvent(
        _ event: EventAddMethod,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?) {

        getUser {
            switch event {
            case .easy(event: let event):
                self.addEventToCalendar(event, onSuccess: onSuccess, onError: onError)

            case .fromModal(event: let event):
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

    // MARK: Methods(Private)

    private func getUser(
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: @escaping EventsManagerEmptyCompletion
    ) {

        if let currentUser = GIDSignIn.sharedInstance().currentUser,
           let _ = currentUser.authentication {
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

    private func addEventToCalendar(
        _ event: EventModel,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?
    ) {

        guard let service = calendarService else {
            onError?(.message(Constants.Error.serviceError))
            return
        }

        let newEvent: GTLRCalendar_Event = GTLRCalendar_Event()

        newEvent.start = buildDate(form: event.startDate)
        newEvent.end = buildDate(form: event.endDate)
        newEvent.reminders?.useDefault = 7

        /// event title
        newEvent.summary = event.title

        /// event description text
        /// support html strings
        newEvent.descriptionProperty = event.description

        let query = GTLRCalendarQuery_EventsInsert.query(withObject: newEvent, calendarId: calendarID)
        service.executeQuery(query) { ticket, event, error in

            if let error = error {
                onError?(.error(error))
            }
            else {
                onSuccess()
            }
        }
    }

    // Helper to build date

    private func buildDate(form date: Date) -> GTLRCalendar_EventDateTime {
        let datetime = GTLRDateTime(date: date)
        let dateObject = GTLRCalendar_EventDateTime()
        dateObject.dateTime = datetime
        return dateObject
    }
}

// TODO: - Update GoogleSDK to the latest version

final class GoogleSignInService: NSObject, GIDSignInDelegate {

    typealias LoginCompletion = (Bool) -> Void

    private enum Scopes {
        static let calendar = "https://www.googleapis.com/auth/calendar"
        static let calendarEvents = "https://www.googleapis.com/auth/calendar.events"
    }

    // MARK: Completions

    var onSignIn: LoginCompletion?

    // MARK: Properties(Private)

    private let clientID: String!

    // MARK: Initializer

    init(_ controller: UIViewController, _ clientID: String) {
        self.clientID = clientID

        super.init()

        configure(on: controller)
    }

    // MARK: Methods(Private)

    private func configure( on controller: UIViewController) {
        GIDSignIn.sharedInstance().clientID = clientID
        GIDSignIn.sharedInstance().scopes = [Scopes.calendar, Scopes.calendarEvents]
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
