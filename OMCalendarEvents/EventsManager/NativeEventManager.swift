//  Created by Ostap Marchenko on 7/30/21.

import UIKit
import EventKit
import EventKitUI

private extension EventModel {
    init(_ event: EKEvent) {
        self.init(start: event.startDate, end: event.endDate, title: event.title, id: event.eventIdentifier, description: event.notes)
    }
}

class NativeEventManager: NSObject {

    private enum Constants {

        enum Error {
            static let selfnil: String = "\nNativeEventManager == nil\n"
            static let unknownError: String = "\nunknown error\n"
            static let predicateError: String = "\nEvents list predicate error\n"
            static let notValidEvent: String = "\nEvent not valid...\n"
            static let eventAlredyExist: String = "\nEvent already exist\n"
            static let removeEventError: String = "\nEvent remove error\n"
            static let cantFindEvent: String = "\nCan't find event in calendar\n"
        }

        enum Success {
            static let eventRemoved: String = "\nIOS Calendar event removed\n"
            static let eventAdded: String = "\nIOS Calendar event added\n"
        }

        static let minutesInYear: Int = 525_600
        static let minutesInHour: Int = 60
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

    internal
    func addEvent(
        _ event: EventAddMethod,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: EventsManagerError?
    ) {

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

    internal
    func getAllEvents(
        from startDate: Date,
        to endDate: Date,
        onSuccess: @escaping AllNativeEventsCompletion,
        onError: @escaping EventsManagerError
    ) {

        requestAuthorization(onSuccess: { [weak self] in
            guard let predicate = self?.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil) else {
                onError(.message(Constants.Error.predicateError))
                return
            }

            let events = self?.eventStore.events(matching: predicate) ?? []
            onSuccess(events)
        },

        onError: { error in
            onError(error)
        }
        )
    }

    /// check if event already added to the calendar

    internal
    func eventExists(
        _ newEvent: EventModel,
        statusCompletion: @escaping EventsManagerStatusCompletion,
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
                            || event.eventIdentifier == newEvent.id
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

    /// by default event will be searched in range of 2 years
    /// if you want change range, update 'inRange' param

    internal
    func removeEvent(
        _ event: EventModel,
        inRange: (from: Date, to: Date)? = nil,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: @escaping EventsManagerError
    ) {

        requestAuthorization(
            onSuccess: { [weak self] in

                guard let self = self else {
                    onError(.message(Constants.Error.unknownError))
                    return
                }

                self.getAllEvents(
                    from: inRange?.from ?? Date().adding(minutes: -Constants.minutesInYear),
                    to: inRange?.to ?? Date().adding(minutes: Constants.minutesInYear),
                    onSuccess: { allEvents in

                        if let eventToRemove = allEvents.first(
                            where: { $0.eventIdentifier == event.id || (
                                $0.startDate == event.startDate
                                    && $0.endDate == event.endDate
                                    && $0.title == event.title
                            )
                            }
                        ) {
                            self.removeEvent(eventToRemove, onSuccess: onSuccess, onError: onError)
                        }
                        else {
                            onError(.message(Constants.Error.cantFindEvent))
                        }
                    },

                    onError: { error in
                        onError(error)
                    }
                )
            },

            onError: { error in
                onError(error)
            }
        )
    }

    // MARK: - Authorization

    internal
    func requestAuthorization(
        onSuccess: @escaping EventsManagerEmptyCompletion,
        onError: @escaping EventsManagerError
    ) {
        switch authorizationStatus {
        case .authorized:
            onSuccess()

        case .notDetermined:

            // Request access to the calendar
            requestAccess { accessGranted, error in

                if let error = error {
                    onError(.error(error))
                }
                else {
                    if accessGranted {
                        onSuccess()
                    }
                    else {
                        onError(.accessStatus(accessGranted))
                    }
                }
            }

        case .denied, .restricted:

            onError(.authorizationStatus(authorizationStatus))

        @unknown default:
            onError(.message(Constants.Error.unknownError))
        }
    }

    // MARK: Private(Methods)

    private func requestAccess(
        completion: @escaping EKEventStoreRequestAccessCompletionHandler
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.eventStore.requestAccess(to: EKEntityType.event) { accessGranted, error in
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
                startDate = startDate.adding(minutes: -Constants.minutesInHour)
            }

            if endInSummerTime {
                endDate = endDate.adding(minutes: -Constants.minutesInHour)
            }
        }
        else {
            if !startInSummerTime {
                startDate = startDate.adding(minutes: Constants.minutesInHour)
            }

            if !endInSummerTime {
                endDate = endDate.adding(minutes: Constants.minutesInHour)
            }
        }

        newEvent.title = eventTitle
        newEvent.notes = eventDescription ?? ""
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.location = event.location
        newEvent.url = event.url
        newEvent.calendar = eventStore.defaultCalendarForNewEvents

        return newEvent
    }

    private func removeEvent(
        _ event: EKEvent,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: @escaping EventsManagerError
    ) {

        do {
            try self.eventStore.remove(event, span: .thisEvent, commit: true)
            onSuccess(Constants.Success.eventRemoved)
        }

        catch {
            onError(.message(Constants.Error.removeEventError))
        }
    }

    // Try to save an event to the calendar

    private func generateAndAddEvent(
        _ event: EventModel?,
        onSuccess: @escaping EventsManagerTextCompletion,
        onError: EventsManagerError?
    ) {

        guard let event = event else {
            onError?(.message(Constants.Error.notValidEvent))
            return
        }

        eventExists(
            event,
            statusCompletion: { [weak self] status in
                if !status {
                    do {
                        guard let self = self else {
                            onError?(.message(Constants.Error.selfnil))
                            return
                        }

                        let eventToAdd = self.generateEvent(event: event)
                        try self.eventStore.save(eventToAdd, span: .thisEvent)
                        onSuccess(Constants.Success.eventAdded)
                    }

                    catch let error as NSError {
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

        if let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            rootVC.present(eventModalController, animated: true)
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
        let validateTest = NSPredicate(format: "SELF MATCHES %@", "<[a-z][\\s\\S]*>")
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
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}
