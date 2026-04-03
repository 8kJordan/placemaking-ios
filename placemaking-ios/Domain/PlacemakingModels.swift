//
//  PlacemakingModels.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import CoreLocation
import Foundation

struct GeoCoordinate: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ProjectBoundary: Codable, Equatable, Hashable {
    var center: GeoCoordinate
    var widthMeters: Double
    var heightMeters: Double

    var areaSquareMeters: Double {
        widthMeters * heightMeters
    }
}

struct ZoneFootprint: Codable, Equatable, Hashable {
    var originXMeters: Double
    var originYMeters: Double
    var widthMeters: Double
    var heightMeters: Double

    var areaSquareMeters: Double {
        widthMeters * heightMeters
    }
}

enum ZoneStatus: String, Codable, CaseIterable, Hashable, Identifiable {
    case notStarted
    case inProgress
    case complete

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .notStarted:
            "Not Started"
        case .inProgress:
            "In Progress"
        case .complete:
            "Complete"
        }
    }
}

struct Zone: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var rowIndex: Int
    var columnIndex: Int
    var footprint: ZoneFootprint
    var status: ZoneStatus
}

struct Project: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var boundary: ProjectBoundary
    var zones: [Zone]

    var sortedZones: [Zone] {
        zones.sorted {
            if $0.rowIndex != $1.rowIndex {
                return $0.rowIndex < $1.rowIndex
            }
            return $0.columnIndex < $1.columnIndex
        }
    }

    var zoneCountSummary: [ZoneStatus: Int] {
        ZoneStatus.allCases.reduce(into: [:]) { partialResult, status in
            partialResult[status] = zones.filter { $0.status == status }.count
        }
    }
}

struct MapSelectionResult: Codable, Equatable, Hashable {
    var boundary: ProjectBoundary
}

enum ProjectLocationChoice: String, CaseIterable, Identifiable {
    case currentLocation
    case arbitrary

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .currentLocation:
            "Use Current Location"
        case .arbitrary:
            "Pick Arbitrary Location"
        }
    }

    var subtitle: String {
        switch self {
        case .currentLocation:
            "Center the map on where you are and shape the footprint from there."
        case .arbitrary:
            "Start from a default map center and pan anywhere before setting the boundary."
        }
    }
}
