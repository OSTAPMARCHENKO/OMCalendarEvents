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
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            title: "Event test title",
            description: "Test event description",
            url: "https://some.test.url"
        )
    }()

    // MARK: Methods(Private)

    private func addEventToNativeCalendar(_ event: EventModel, completion: OnEmptyAction? = nil) {

        /// event:  .fromModal(someDefaultEvent) - here you you will see modal screen where you will be able to create or edit event
        /// event:  .easy(someDefaultEvent) - here you will add an event to the calendar immediately

        calendarManager.add(
            event: .fromModal(event),
            to: .native,
            onSuccess: {
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
            to: .google(
                on: self,
                clientID: "*** your google client_id ***"
            ),
            onSuccess: {
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
            print("authorizationStatus - \(status)")

        case .accessStatus(let status):
            print("accessStatus - \(status)")

        case .error(let error):
            print(error.localizedDescription)

        case .message(let message):
            print(message)

        default:
            return
        }
    }

    // MARK: IBActions

    @IBAction private func googlePressed() {
        addEventToNativeCalendar(
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
