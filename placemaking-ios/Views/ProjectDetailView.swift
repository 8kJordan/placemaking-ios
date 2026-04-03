//
//  ProjectDetailView.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject private var projectStore: ProjectStore

    let projectID: UUID

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12),
    ]

    var body: some View {
        Group {
            if let project = projectStore.project(withID: projectID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        overviewCard(project)
                        statsRow(project)
                        zonesSection(project)
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(project.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Project Missing", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func overviewCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Overview")
                .font(.title2.weight(.bold))
                .accessibilityIdentifier("projectOverviewTitle")

            Text("The rectangular map footprint defines the total scanable area. Each zone below represents an independently trackable chunk for the eventual LiDAR capture pass.")
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                MeasurementStat(title: "Width", value: project.boundary.widthMeters.lengthText)
                MeasurementStat(title: "Height", value: project.boundary.heightMeters.lengthText)
                MeasurementStat(title: "Area", value: project.boundary.areaSquareMeters.areaText)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.86, green: 0.92, blue: 0.93), Color(red: 0.96, green: 0.95, blue: 0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func statsRow(_ project: Project) -> some View {
        HStack(spacing: 12) {
            ZoneStatusBadge(status: .notStarted, count: project.zoneCountSummary[.notStarted] ?? 0)
            ZoneStatusBadge(status: .inProgress, count: project.zoneCountSummary[.inProgress] ?? 0)
            ZoneStatusBadge(status: .complete, count: project.zoneCountSummary[.complete] ?? 0)
        }
    }

    private func zonesSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zones")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(project.sortedZones) { zone in
                    NavigationLink {
                        ZoneDetailView(projectID: project.id, zoneID: zone.id)
                    } label: {
                        ZoneTile(zone: zone)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("zoneTile_\(zone.name)")
                }
            }
        }
    }
}

private struct ZoneTile: View {
    let zone: Zone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(zone.name)
                    .font(.title3.weight(.bold))
                Spacer()
                Circle()
                    .fill(zone.status.color)
                    .frame(width: 12, height: 12)
            }

            Text(zone.status.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(zone.status.color)

            Text("\(zone.footprint.widthMeters.lengthText) × \(zone.footprint.heightMeters.lengthText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ZoneStatusBadge: View {
    let status: ZoneStatus
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status.color)
            Text("\(count)")
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(status.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension ZoneStatus {
    var color: Color {
        switch self {
        case .notStarted:
            Color.orange
        case .inProgress:
            Color.blue
        case .complete:
            Color.green
        }
    }
}
