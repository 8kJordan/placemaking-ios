//
//  ZoneDetailView.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import SwiftUI

struct ZoneDetailView: View {
    @EnvironmentObject private var projectStore: ProjectStore

    let projectID: UUID
    let zoneID: UUID

    @State private var errorMessage: String?

    var body: some View {
        Group {
            if
                let project = projectStore.project(withID: projectID),
                let zone = project.zones.first(where: { $0.id == zoneID })
            {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(zone.name)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                            Text("LiDAR capture is not implemented in this beta. Use this screen to review the footprint and manually track the zone’s scan state while the capture flow is still a placeholder.")
                                .foregroundStyle(.secondary)
                        }

                        detailCard(title: "Zone Status") {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(zone.status.color)
                                    .frame(width: 12, height: 12)
                                Text(zone.status.displayName)
                                    .font(.headline)
                            }
                        }

                        detailCard(title: "Zone Footprint") {
                            HStack(spacing: 12) {
                                MeasurementStat(title: "Width", value: zone.footprint.widthMeters.lengthText)
                                MeasurementStat(title: "Height", value: zone.footprint.heightMeters.lengthText)
                                MeasurementStat(title: "Area", value: zone.footprint.areaSquareMeters.areaText)
                            }
                        }

                        detailCard(title: "Project Context") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(project.name)
                                    .font(.headline)
                                Text("Row \(zone.rowIndex + 1), Column \(zone.columnIndex + 1)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manual Status Controls")
                                .font(.headline)

                            statusButton("Mark In Progress", status: .inProgress, identifier: "markZoneInProgressButton")
                            statusButton("Mark Complete", status: .complete, identifier: "markZoneCompleteButton")
                            statusButton("Reset to Not Started", status: .notStarted, identifier: "resetZoneStatusButton")
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(zone.name)
                .navigationBarTitleDisplayMode(.inline)
                .alert("Couldn’t Update Zone", isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            errorMessage = nil
                        }
                    }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }
            } else {
                ContentUnavailableView("Zone Missing", systemImage: "square.dashed")
            }
        }
    }

    private func detailCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statusButton(_ title: String, status: ZoneStatus, identifier: String) -> some View {
        Button {
            do {
                try projectStore.updateZoneStatus(projectID: projectID, zoneID: zoneID, status: status)
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(status.color.opacity(0.12))
                .foregroundStyle(status.color)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
