//
//  ViewController.swift
//  OMExample
//
//  Created by Ostap Marchenko on 8/12/21.
//

import UIKit
import OMCalendarEvents

class ViewController: UIViewController {

    private lazy var eventManager: EventsCalendarManager = {
        EventsCalendarManager()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addEvent()
    }


    private func addEvent() {

    }

}

