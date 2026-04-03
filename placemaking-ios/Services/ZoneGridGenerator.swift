//
//  ZoneGridGenerator.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Foundation

struct ZoneGridGenerator: Sendable {
    let maxZoneEdgeMeters: Double

    nonisolated init(maxZoneEdgeMeters: Double = 9.0) {
        self.maxZoneEdgeMeters = maxZoneEdgeMeters
    }

    nonisolated func generateZones(for boundary: ProjectBoundary) -> [Zone] {
        let columnCount = max(1, Int(ceil(boundary.widthMeters / maxZoneEdgeMeters)))
        let rowCount = max(1, Int(ceil(boundary.heightMeters / maxZoneEdgeMeters)))

        var zones: [Zone] = []
        zones.reserveCapacity(columnCount * rowCount)

        for rowIndex in 0..<rowCount {
            let originYMeters = Double(rowIndex) * maxZoneEdgeMeters
            let zoneHeight = rowIndex == rowCount - 1
                ? max(boundary.heightMeters - originYMeters, 0.0)
                : maxZoneEdgeMeters

            for columnIndex in 0..<columnCount {
                let originXMeters = Double(columnIndex) * maxZoneEdgeMeters
                let zoneWidth = columnIndex == columnCount - 1
                    ? max(boundary.widthMeters - originXMeters, 0.0)
                    : maxZoneEdgeMeters

                zones.append(
                    Zone(
                        id: UUID(),
                        name: zoneName(rowIndex: rowIndex, columnIndex: columnIndex),
                        rowIndex: rowIndex,
                        columnIndex: columnIndex,
                        footprint: ZoneFootprint(
                            originXMeters: originXMeters,
                            originYMeters: originYMeters,
                            widthMeters: max(zoneWidth, 0.0),
                            heightMeters: max(zoneHeight, 0.0)
                        ),
                        status: .notStarted
                    )
                )
            }
        }

        return zones
    }

    nonisolated private func zoneName(rowIndex: Int, columnIndex: Int) -> String {
        "\(rowLabel(for: rowIndex))\(columnIndex + 1)"
    }

    nonisolated private func rowLabel(for rowIndex: Int) -> String {
        var remainder = rowIndex
        var label = ""

        repeat {
            let scalar = UnicodeScalar(65 + (remainder % 26)) ?? "A"
            label = "\(Character(scalar))" + label
            remainder = remainder / 26 - 1
        } while remainder >= 0

        return label
    }
}
