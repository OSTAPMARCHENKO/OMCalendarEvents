//  Created by Ostap Marchenko on 7/30/21.

import UIKit
import EventKit
import EventKitUI

private extension EventModel {
    init(_ event: EKEvent) {
        self.init(start: event.startDate, end: event.endDate, title: event.title, id: event.eventIdentifier, description: event.notes, url: nil)
    }
}

class NativeEventManager: NSObject {

    private enum Constants {

        enum Error {
            static let unknownError: String = "\n\n=== unknown error === \n\n"
            static let predicateError: String = "\n\n=== Events list predicate error === \n\n"
            static let notValidEvent: String = "\n\n=== Event not valid... === \n\n"
            static let eventAlredyExist: String = "\n\n=== Event already exist === \n\n"
        }
    }

    // MARK: Completions

    var onEditingEnd: EventsManagerEmptyCompletion?

    private lazy var eventStore: EKEventStore = {
        EKEventStore()
    }()

    private var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: EKEntityType.event)
    }

    // MARK: Public(Methods)

    public func addEvent(
        _ event: EventAddMethod,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?) {

        requestAuthorization(onSuccess: { [weak self] in
            switch event {
            case .easy(let event):
                self?.generateAndAddEvent(event, onSuccess: onSuccess, onError: onError)

            case .fromModal(let event):
                DispatchQueue.main.async {
                    self?.presentEventCalendarDetailModal(event: event)
                }
            }
        },
        onError: { error in
            onError?(error)
        }
        )
    }

    public func getAllEvents(
        from startDate: Date,
        to endDate: Date,
        onSuccess: @escaping EventsManagerEventsCompletion,
        onError: @escaping EventsManagerError
    ) {

        requestAuthorization(onSuccess: { [weak self] in
            guard let predicate = self?.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil) else {
                onError(.message(Constants.Error.predicateError))
                return
            }

            let events = self?.eventStore.events(matching: predicate) ?? []
            let mapped = events.map({ EventModel( $0 ) })

            onSuccess(mapped)
        },
        onError: { error in
            onError(error)
        }
        )
    }

    public func eventExists(
        _ newEvent: EventModel,
        statusCompletion: @escaping (Bool) -> Void,
        onError: @escaping EventsManagerError
    ) {
        requestAuthorization(onSuccess: { [weak self] in
            self?.getAllEvents(
                from: newEvent.startDate,
                to: newEvent.endDate,
                onSuccess: { events in

                    let eventContains = events.contains { event in
                            (event.title == newEvent.title
                                && event.startDate == newEvent.startDate
                                && event.endDate == newEvent.endDate)

                                /// event can be edited by user so need to check ID also
                                || event.id == newEvent.id
                    }

                    statusCompletion(eventContains)

                },
                onError: onError
            )
        },
        onError: { error in
            onError(error)
        }
        )
    }

    //MARK: - Authorization

    public func requestAuthorization(
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: @escaping EventsManagerError
    ) {
        switch authorizationStatus {
        case .authorized:
            onSuccess()

        case .notDetermined:
            //Request access to the calendar
            requestAccess { (accessGranted, error) in

                if let error = error {
                    onError(.error(error))
                }
                else {
                    if accessGranted {
                        onSuccess()
                    } else {
                        onError(.accessStatus(accessGranted))
                    }
                }
            }

        case .denied,
             .restricted:
            onError(.authorizationStatus(authorizationStatus))

        @unknown default:
            onError(.message(Constants.Error.unknownError))
        }
    }

    // MARK: Private(Methods)

    private func removeEvent(
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: @escaping EventsManagerError
    ) {

        requestAuthorization(onSuccess: {


        },
        onError: { error in
            onError(error)
        }
        )
    }

    private func requestAccess(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        DispatchQueue.main.async { [weak self] in
            self?.eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
                completion(accessGranted, error)
            }
        }
    }

    // Generate an event which will be then added to the calendar

    private func generateEvent(event: EventModel) -> EKEvent {

        let eventTitle: String? = event.title.isHtml() ? event.title.attributedText()?.string : event.title
        let eventDescription: String? = event.description?.isHtml() ?? false ? event.description?.attributedText()?.string : event.description
        let newEvent = EKEvent(eventStore: eventStore)

        var startDate = event.startDate
        var endDate = event.endDate

        /// check is timeZone in summer/winter period
        let timeZone = NSTimeZone.local
        let currentTimeIsSummer = timeZone.isDaylightSavingTime(for: Date())

        let startInSummerTime = timeZone.isDaylightSavingTime(for: startDate)
        let endInSummerTime = timeZone.isDaylightSavingTime(for: endDate)

        /// without this validation, you will get issue in calendar when event startTime in summer time zone and endTime in winter
        if !currentTimeIsSummer {
            if startInSummerTime {
                startDate = startDate.adding(minutes: -1 * 60)
            }
            if endInSummerTime {
                endDate = endDate.adding(minutes: -1 * 60)
            }
        }
        else {
            if !startInSummerTime {
                startDate = startDate.adding(minutes: 1 * 60)
            }
            if !endInSummerTime {
                endDate = endDate.adding(minutes: 1 * 60)
            }
        }

        newEvent.title = eventTitle
        newEvent.notes = eventDescription ?? ""
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        return newEvent
    }

    // Try to save an event to the calendar

    private func generateAndAddEvent(
        _ event: EventModel?,
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: EventsManagerError?) {

        guard let event = event else {
            onError?(.message(Constants.Error.notValidEvent))
            return
        }


        eventExists(event, statusCompletion: { [weak self] status in
            if status {
                do {
                    guard let self = self else {
                        onError?(.message("\n\n self == nil \n\n"))
                        return
                    }

                    let eventToAdd = self.generateEvent(event: event)
                    try self.eventStore.save(eventToAdd, span: .thisEvent)
                    onSuccess()

                }  catch let error as NSError {
                    onError?(.error(error))
                }
            }
            else {
                onError?(.message(Constants.Error.eventAlredyExist))
            }
        },

        onError: { error in
            onError?(error)
        }
        )
    }

    // Present edit event calendar modal

    private func presentEventCalendarDetailModal(event: EventModel?) {
        let eventModalController = EKEventEditViewController()
        eventModalController.editViewDelegate = self
        eventModalController.eventStore = eventStore

        if let event = event {
            let event = generateEvent(event: event)
            eventModalController.event = event
        }

        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.present(eventModalController, animated: true, completion: nil)
        }
    }
}

// EKEventEditViewDelegate
extension NativeEventManager: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: onEditingEnd)
    }
}

// MARK: Private extensions

private extension String {
    func isHtml() -> Bool {
        let validateTest = NSPredicate(format:"SELF MATCHES %@", "<[a-z][\\s\\S]*>")
        return validateTest.evaluate(with: self)
    }

    func attributedText() -> NSAttributedString? {
        if self.isHtml() {
            let data = Data(self.utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                return attributedString
            }
        }
        return nil
    }
}

private extension Date {
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}

