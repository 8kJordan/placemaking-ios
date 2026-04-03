//
//  StoredProject.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Foundation
import SwiftData

@Model
final class StoredProject {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var centerLatitude: Double
    var centerLongitude: Double
    var widthMeters: Double
    var heightMeters: Double

    @Relationship(deleteRule: .cascade, inverse: \StoredZone.project)
    var zones: [StoredZone]

    init(
        id: UUID,
        name: String,
        createdAt: Date,
        centerLatitude: Double,
        centerLongitude: Double,
        widthMeters: Double,
        heightMeters: Double,
        zones: [StoredZone] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.zones = zones
    }
}

@Model
final class StoredZone {
    @Attribute(.unique) var id: UUID
    var name: String
    var rowIndex: Int
    var columnIndex: Int
    var originXMeters: Double
    var originYMeters: Double
    var widthMeters: Double
    var heightMeters: Double
    var statusRawValue: String
    var project: StoredProject?

    init(
        id: UUID,
        name: String,
        rowIndex: Int,
        columnIndex: Int,
        originXMeters: Double,
        originYMeters: Double,
        widthMeters: Double,
        heightMeters: Double,
        statusRawValue: String,
        project: StoredProject? = nil
    ) {
        self.id = id
        self.name = name
        self.rowIndex = rowIndex
        self.columnIndex = columnIndex
        self.originXMeters = originXMeters
        self.originYMeters = originYMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.statusRawValue = statusRawValue
        self.project = project
    }
}
