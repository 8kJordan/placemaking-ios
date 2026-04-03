//
//  placemaking_iosTests.swift
//  placemaking-iosTests
//
//  Created by PC1 on 4/1/26.
//

import Testing
import SwiftData
@testable import placemaking_ios

@MainActor
struct placemaking_iosTests {

    @Test func smallBoundaryCreatesSingleZone() {
        let generator = ZoneGridGenerator()
        let zones = generator.generateZones(for: ProjectBoundary(
            center: GeoCoordinate(latitude: 0, longitude: 0),
            widthMeters: 8,
            heightMeters: 7
        ))

        #expect(zones.count == 1)
        #expect(zones[0].name == "A1")
        #expect(zones[0].footprint.widthMeters == 8)
        #expect(zones[0].footprint.heightMeters == 7)
    }

    @Test func exactMultiplesCreateFullSquares() {
        let generator = ZoneGridGenerator()
        let zones = generator.generateZones(for: ProjectBoundary(
            center: GeoCoordinate(latitude: 0, longitude: 0),
            widthMeters: 18,
            heightMeters: 18
        ))

        #expect(zones.count == 4)
        #expect(zones.map(\.name) == ["A1", "A2", "B1", "B2"])
        #expect(zones.allSatisfy { $0.footprint.widthMeters == 9 && $0.footprint.heightMeters == 9 })
    }

    @Test func unevenBoundaryCreatesSmallerEdgeZones() {
        let generator = ZoneGridGenerator()
        let zones = generator.generateZones(for: ProjectBoundary(
            center: GeoCoordinate(latitude: 0, longitude: 0),
            widthMeters: 20,
            heightMeters: 11
        ))

        #expect(zones.count == 6)
        #expect(zones.first(where: { $0.name == "A3" })?.footprint.widthMeters == 2)
        #expect(zones.first(where: { $0.name == "B1" })?.footprint.heightMeters == 2)
        #expect(zones.first(where: { $0.name == "B3" })?.footprint.widthMeters == 2)
        #expect(zones.first(where: { $0.name == "B3" })?.footprint.heightMeters == 2)
    }

    @Test func creationValidationRequiresNameAndBoundary() {
        let validBoundary = ProjectBoundary(
            center: GeoCoordinate(latitude: 0, longitude: 0),
            widthMeters: 10,
            heightMeters: 10
        )

        #expect(ProjectCreationValidator.canCreateProject(named: "", boundary: validBoundary) == false)
        #expect(ProjectCreationValidator.canCreateProject(named: "Campus", boundary: nil) == false)
        #expect(ProjectCreationValidator.canCreateProject(named: "Campus", boundary: validBoundary) == true)
    }

    @Test func persistenceRoundTripPreservesProjectsAndZoneStatus() throws {
        let schema = Schema([
            StoredProject.self,
            StoredZone.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])

        let store = ProjectStore(container: container)
        let project = try store.createProject(
            named: "Campus North",
            boundary: ProjectBoundary(
                center: GeoCoordinate(latitude: 37.0, longitude: -122.0),
                widthMeters: 18,
                heightMeters: 9
            )
        )

        let firstZone = try #require(project.sortedZones.first)
        try store.updateZoneStatus(projectID: project.id, zoneID: firstZone.id, status: .complete)

        let reloadedStore = ProjectStore(container: container)
        let reloadedProject = try #require(reloadedStore.project(withID: project.id))
        let reloadedZone = try #require(reloadedProject.sortedZones.first(where: { $0.id == firstZone.id }))

        #expect(reloadedStore.projects.count == 1)
        #expect(reloadedProject.name == "Campus North")
        #expect(reloadedZone.status == .complete)
    }
}
