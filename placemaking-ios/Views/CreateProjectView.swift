//
//  CreateProjectView.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var projectStore: ProjectStore

    let onCreated: (Project) -> Void

    @State private var projectName = ""
    @State private var selectedBoundary: ProjectBoundary?
    @State private var locationChoice: ProjectLocationChoice = .currentLocation
    @State private var isShowingBoundarySelector = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                onboardingCard
                nameSection
                locationSection
                boundarySection
                createButton
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isShowingBoundarySelector) {
            BoundaryMapSelectionView(
                startingPoint: locationChoice,
                existingBoundary: selectedBoundary
            ) { selection in
                selectedBoundary = selection.boundary
            }
        }
        .alert("Couldn’t Create Project", isPresented: Binding(
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
    }

    private var onboardingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set the footprint before you scan.")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("This beta creates a map-defined project, calculates its total footprint, and splits the site into scanable zones capped at 9 meters for the main grid.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                PillLabel(text: "Local-first")
                PillLabel(text: "Zone grid")
                PillLabel(text: "LiDAR stub")
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Project Name")
                .font(.headline)

            TextField("Example: North Plaza Survey", text: $projectName)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("projectNameField")
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Map Starting Point")
                .font(.headline)

            ForEach(ProjectLocationChoice.allCases) { choice in
                Button {
                    openBoundaryMap(for: choice)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: locationChoice == choice ? "largecircle.fill.circle" : "circle")
                            .font(.title3)
                            .foregroundStyle(locationChoice == choice ? Color.accentColor : .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(choice.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(choice.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(choice == .currentLocation ? "locationChoiceCurrent" : "locationChoiceArbitrary")
            }

            Text("Selecting one of these options now opens the boundary map immediately.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var boundarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Boundary")
                .font(.headline)

            Text("Open the map, place the rectangular footprint, then confirm the live dimensions and total area.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                isShowingBoundarySelector = true
            } label: {
                HStack {
                    Image(systemName: selectedBoundary == nil ? "map.fill" : "mappin.and.ellipse")
                    Text(selectedBoundary == nil ? "Open Boundary Map" : "Adjust Boundary on Map")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(selectedBoundary == nil ? "Next" : "Edit")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(18)
                .background(Color.accentColor.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chooseBoundaryButton")

            if let selectedBoundary {
                BoundarySummaryCard(boundary: selectedBoundary)
            }
        }
    }

    private var createButton: some View {
        Button {
            do {
                let project = try projectStore.createProject(
                    named: projectName,
                    boundary: selectedBoundary ?? ProjectBoundary(
                        center: GeoCoordinate(latitude: 0, longitude: 0),
                        widthMeters: 0,
                        heightMeters: 0
                    )
                )
                onCreated(project)
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Text("Create Project")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canCreateProject ? Color.accentColor : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canCreateProject)
        .accessibilityIdentifier("createProjectSubmitButton")
    }

    private var canCreateProject: Bool {
        ProjectCreationValidator.canCreateProject(named: projectName, boundary: selectedBoundary)
    }

    private func openBoundaryMap(for choice: ProjectLocationChoice) {
        locationChoice = choice
        isShowingBoundarySelector = true
    }
}

private struct BoundarySummaryCard: View {
    let boundary: ProjectBoundary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Selected Footprint")
                .font(.headline)

            HStack(spacing: 12) {
                MeasurementStat(title: "Width", value: boundary.widthMeters.lengthText)
                MeasurementStat(title: "Height", value: boundary.heightMeters.lengthText)
                MeasurementStat(title: "Area", value: boundary.areaSquareMeters.areaText)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct MeasurementStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PillLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }
}
