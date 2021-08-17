//
//  ViewController.swift
//  OMExample
//
//  Created by Ostap Marchenko on 8/12/21.
//

import UIKit
import OMCalendarEvents

class ViewController: UIViewController {

    typealias OnEmptyAction = () -> Void

    // MARK: Properties(Private)

    private lazy var calendarManager: EventsCalendarManager = {
        EventsCalendarManager()
    }()

    private lazy var someDefaultEvent: EventModel = {
        EventModel(
            start: DateFormatters.generalTimeFormatter.date(from: "2021-08-17 12:01:00") ?? Date(),
            end: DateFormatters.generalTimeFormatter.date(from: "2021-08-17 13:03:00") ?? Date(),
            title: "Event test title",
            description: "Test event description" /// optional
        )
    }()

    private var testID: String {
        "608992408536-gekct0lu1rj7e2esuvg56donsmc2hpa4.apps.googleusercontent.com"
    }

    // MARK: Methods(Private)

    private func addEventToNativeCalendar(_ event: EventModel, completion: OnEmptyAction? = nil) {

        /// event:  .fromModal(event) - here you you will see modal screen where you will be able to create or edit event
        /// event:  .easy(event) - here you will add an event to the calendar immediately

        calendarManager.add(
            event: .fromModal(event),
            to: [
                .native
            ],
            onSuccess: { statusMessage in
                debugPrint(statusMessage)
                completion?()
            },

            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }

    private func addEventToGoogleCalendar(_ event: EventModel, completion: OnEmptyAction? = nil) {

        /// Google calendar haven't modal screen, so please use - .easy

        calendarManager.add(
            event: .easy(event),
            to: [
                .google(from: self, clientID: testID)
            ],
            onSuccess: { statusMessage in
                debugPrint(statusMessage)
                completion?()
            },

            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }

    private func removeEventFromGoogleCalendar(_ event: EventModel, completion: OnEmptyAction? = nil) {

        calendarManager.remove(
            event: event,
            from: [.google(from: self, clientID: testID)],
            onSuccess: { statusMessage in
                debugPrint(statusMessage)
                completion?()
            },

            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }

    private func removeEventFromNativeCalendar(_ event: EventModel, completion: OnEmptyAction? = nil) {

        calendarManager.remove(
            event: event,
            from: [.native],
            onSuccess: { statusMessage in
                debugPrint(statusMessage)
                completion?()
            },

            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }

    private func handleError(_ error: EventManagerError?) {

        switch error {
        case .authorizationStatus(let status):
            debugPrint("authorizationStatus - \(status)")

        case .accessStatus(let status):
            debugPrint("accessStatus - \(status)")

        case .error(let error):
            debugPrint("error - \(error.localizedDescription)")

        case .message(let message):
            debugPrint("message - \(message)")

        default:
            return
        }
    }

    // MARK: IBActions
    
    @IBAction private func googleRemovePressed() {
        removeEventFromGoogleCalendar(
            someDefaultEvent,
            completion: {
                /// Do something
            }
        )
    }

    @IBAction private func iosRemovePressed() {
        removeEventFromNativeCalendar(
            someDefaultEvent,
            completion: {
                /// Do something
            }
        )
    }
    
    @IBAction private func googlePressed() {
        addEventToGoogleCalendar(
            someDefaultEvent,
            completion: {
                /// Do something
            }
        )
    }

    @IBAction private func iosPressed() {
        addEventToNativeCalendar(
            someDefaultEvent,
            completion: {
                /// Do something
            }
        )
    }
}
