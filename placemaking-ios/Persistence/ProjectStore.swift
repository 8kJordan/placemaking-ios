//
//  ProjectStore.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Combine
import Foundation
import SwiftData

@MainActor
protocol ProjectRepository: AnyObject {
    var projects: [Project] { get }
    func createProject(named name: String, boundary: ProjectBoundary) throws -> Project
    func project(withID id: UUID) -> Project?
    func updateZoneStatus(projectID: UUID, zoneID: UUID, status: ZoneStatus) throws
    func reload() throws
}

@MainActor
final class ProjectStore: ObservableObject, ProjectRepository {
    @Published private(set) var projects: [Project] = []

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let zoneGridGenerator: ZoneGridGenerator

    init(
        container: ModelContainer,
        zoneGridGenerator: ZoneGridGenerator = ZoneGridGenerator()
    ) {
        self.modelContainer = container
        self.modelContext = ModelContext(container)
        self.zoneGridGenerator = zoneGridGenerator

        do {
            try reload()
        } catch {
            assertionFailure("Failed to load persisted projects: \(error.localizedDescription)")
        }
    }

    func createProject(named name: String, boundary: ProjectBoundary) throws -> Project {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ProjectCreationValidator.canCreateProject(named: trimmedName, boundary: boundary) else {
            throw ProjectStoreError.invalidProjectConfiguration
        }

        let projectID = UUID()
        let zones = zoneGridGenerator.generateZones(for: boundary)
        let storedZones = zones.map { zone in
            StoredZone(
                id: zone.id,
                name: zone.name,
                rowIndex: zone.rowIndex,
                columnIndex: zone.columnIndex,
                originXMeters: zone.footprint.originXMeters,
                originYMeters: zone.footprint.originYMeters,
                widthMeters: zone.footprint.widthMeters,
                heightMeters: zone.footprint.heightMeters,
                statusRawValue: zone.status.rawValue
            )
        }

        let storedProject = StoredProject(
            id: projectID,
            name: trimmedName,
            createdAt: Date(),
            centerLatitude: boundary.center.latitude,
            centerLongitude: boundary.center.longitude,
            widthMeters: boundary.widthMeters,
            heightMeters: boundary.heightMeters,
            zones: storedZones
        )

        for zone in storedZones {
            zone.project = storedProject
        }

        modelContext.insert(storedProject)
        try modelContext.save()
        try reload()

        guard let createdProject = project(withID: projectID) else {
            throw ProjectStoreError.projectNotFound
        }

        return createdProject
    }

    func project(withID id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    func updateZoneStatus(projectID: UUID, zoneID: UUID, status: ZoneStatus) throws {
        let descriptor = FetchDescriptor<StoredProject>(
            predicate: #Predicate { $0.id == projectID }
        )

        guard let storedProject = try modelContext.fetch(descriptor).first else {
            throw ProjectStoreError.projectNotFound
        }

        guard let storedZone = storedProject.zones.first(where: { $0.id == zoneID }) else {
            throw ProjectStoreError.zoneNotFound
        }

        storedZone.statusRawValue = status.rawValue
        try modelContext.save()
        try reload()
    }

    func reload() throws {
        let descriptor = FetchDescriptor<StoredProject>(
            sortBy: [SortDescriptor(\StoredProject.createdAt, order: .reverse)]
        )
        let storedProjects = try modelContext.fetch(descriptor)
        projects = storedProjects.map(Self.makeProject(from:))
    }

    private static func makeProject(from storedProject: StoredProject) -> Project {
        let zones = storedProject.zones.map { storedZone in
            Zone(
                id: storedZone.id,
                name: storedZone.name,
                rowIndex: storedZone.rowIndex,
                columnIndex: storedZone.columnIndex,
                footprint: ZoneFootprint(
                    originXMeters: storedZone.originXMeters,
                    originYMeters: storedZone.originYMeters,
                    widthMeters: storedZone.widthMeters,
                    heightMeters: storedZone.heightMeters
                ),
                status: ZoneStatus(rawValue: storedZone.statusRawValue) ?? .notStarted
            )
        }

        return Project(
            id: storedProject.id,
            name: storedProject.name,
            createdAt: storedProject.createdAt,
            boundary: ProjectBoundary(
                center: GeoCoordinate(
                    latitude: storedProject.centerLatitude,
                    longitude: storedProject.centerLongitude
                ),
                widthMeters: storedProject.widthMeters,
                heightMeters: storedProject.heightMeters
            ),
            zones: zones
        )
    }
}

enum ProjectStoreError: LocalizedError {
    case invalidProjectConfiguration
    case projectNotFound
    case zoneNotFound

    var errorDescription: String? {
        switch self {
        case .invalidProjectConfiguration:
            "Projects need a name and a confirmed boundary before they can be created."
        case .projectNotFound:
            "The selected project could not be found."
        case .zoneNotFound:
            "The selected zone could not be found."
        }
    }
}
