//
//  EventManagerModel.swift
//  OMCalendarEvents
//
//  Created by Ostap Marchenko on 7/30/21.
//

import Foundation

public struct EventModel: Codable {
    let startDate: Date
    let endDate: Date
    let title: String
    var description: String?
    var url: String?
    var id: String?

    public init(
         start: Date,
         end: Date,
         title: String,
         id: String? = nil,
         description: String? = nil,
         url: String? = nil
    ) {
        self.id = id
        self.startDate = start
        self.endDate = end
        self.title = title
        self.description = description
        self.url = url
    }
}
