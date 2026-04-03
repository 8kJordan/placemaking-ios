//
//  ProjectsView.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import SwiftUI

private enum ProjectRoute: Hashable {
    case detail(UUID)
}

struct ProjectsView: View {
    @EnvironmentObject private var projectStore: ProjectStore

    @State private var navigationPath: [ProjectRoute] = []
    @State private var isShowingCreateProject = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if projectStore.projects.isEmpty {
                    emptyState
                } else {
                    populatedState
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreateProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                    .accessibilityIdentifier("createProjectButton")
                }
            }
            .sheet(isPresented: $isShowingCreateProject) {
                NavigationStack {
                    CreateProjectView { project in
                        isShowingCreateProject = false
                        navigationPath.append(.detail(project.id))
                    }
                }
            }
            .navigationDestination(for: ProjectRoute.self) { route in
                switch route {
                case .detail(let projectID):
                    ProjectDetailView(projectID: projectID)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Survey-grade planning for large outdoor scans.")
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Create a project, define a rectangular footprint on Apple Maps, and let the app break that footprint into zones ready for LiDAR capture.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.09, green: 0.13, blue: 0.19), Color(red: 0.16, green: 0.32, blue: 0.26)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "square.grid.3x3.square")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.14))
                        .padding(20)
                }
                .accessibilityIdentifier("projectsHeroCard")

                VStack(alignment: .leading, spacing: 10) {
                    Text("No Projects Yet")
                        .font(.title2.weight(.semibold))
                    Text("Start with a named project and a map-selected footprint. Zones are generated automatically and stay available offline on this device.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)

                Button {
                    isShowingCreateProject = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create First Project")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier("createProjectButton")
            }
            .padding(20)
        }
    }

    private var populatedState: some View {
        List {
            Section {
                ForEach(projectStore.projects) { project in
                    NavigationLink(value: ProjectRoute.detail(project.id)) {
                        ProjectRow(project: project)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.name)
                .font(.headline)

            HStack(spacing: 10) {
                Label("\(project.sortedZones.count) zones", systemImage: "square.grid.3x3.fill")
                Label(project.boundary.areaSquareMeters.areaText, systemImage: "ruler")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ZoneStatusBadge(status: .notStarted, count: project.zoneCountSummary[.notStarted] ?? 0)
                ZoneStatusBadge(status: .inProgress, count: project.zoneCountSummary[.inProgress] ?? 0)
                ZoneStatusBadge(status: .complete, count: project.zoneCountSummary[.complete] ?? 0)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ProjectsView()
        .environmentObject(AppDependencies.preview.projectStore)
}
