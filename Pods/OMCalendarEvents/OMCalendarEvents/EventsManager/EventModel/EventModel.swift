//
//  EventManagerModel.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

import Foundation

public struct EventModel: Codable {
    var id: String?
    let startDate: Date
    let endDate: Date
    let title: String
    let description: String
    var url: String? = nil
}
