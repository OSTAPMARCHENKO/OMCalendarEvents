//
//  ViewController.swift
//  OMExample
//
//  Created by Ostap Marchenko on 8/12/21.
//

import UIKit
import OMCalendarEvents

class ViewController: UIViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()

        addEventToNativeCalendar()
    }

    private func addEventToNativeCalendar() {

        /// event:  .fromModal(someDefaultEvent) - here you you will see modal screen where you will be able to create or edit event
        /// event:  .easy(someDefaultEvent) - here you will add an event to the calendar immediately

        calendarManager.add(
            event: .fromModal(someDefaultEvent),
            to: .native
        ) {
            /// event added successfully
        } onError: { [weak self] error in
            self?.handleError(error)
        }
    }

    private func addEventToGoogleCalendar() {

        /// Google calendar haven't modal screen, so please use - .easy
        ///
        calendarManager.add(
            event: .easy(someDefaultEvent),
            to: .google(
                on: self,
                clientID: ""
            )
        ) {
            /// event added successfully
        } onError: { [weak self] error in
            self?.handleError(error)
        }

    }

    private func handleError(_ error: EventManagerError?) {
        /// you can show different error messages here

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
}
