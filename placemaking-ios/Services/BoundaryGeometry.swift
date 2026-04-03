//
//  BoundaryGeometry.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import CoreLocation
import Foundation

enum BoundaryGeometry {
    private static let metersPerDegreeLatitude = 111_132.0

    static func metersPerDegreeLongitude(at latitude: Double) -> Double {
        max(1.0, 111_320.0 * cos(latitude * .pi / 180.0))
    }

    static func coordinate(
        from origin: GeoCoordinate,
        movingEast eastMeters: Double,
        movingNorth northMeters: Double
    ) -> GeoCoordinate {
        let latitudeDelta = northMeters / metersPerDegreeLatitude
        let longitudeDelta = eastMeters / metersPerDegreeLongitude(at: origin.latitude)

        return GeoCoordinate(
            latitude: origin.latitude + latitudeDelta,
            longitude: origin.longitude + longitudeDelta
        )
    }

    static func corners(for boundary: ProjectBoundary) -> [GeoCoordinate] {
        let halfWidth = boundary.widthMeters / 2.0
        let halfHeight = boundary.heightMeters / 2.0
        let center = boundary.center

        let topLeft = coordinate(from: center, movingEast: -halfWidth, movingNorth: halfHeight)
        let topRight = coordinate(from: center, movingEast: halfWidth, movingNorth: halfHeight)
        let bottomRight = coordinate(from: center, movingEast: halfWidth, movingNorth: -halfHeight)
        let bottomLeft = coordinate(from: center, movingEast: -halfWidth, movingNorth: -halfHeight)

        return [topLeft, topRight, bottomRight, bottomLeft]
    }

    static func distanceMeters(from lhs: GeoCoordinate, to rhs: GeoCoordinate) -> Double {
        let start = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let end = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return start.distance(from: end)
    }
}
