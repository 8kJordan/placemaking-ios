//
//  AppDependencies.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Foundation
import SwiftData

@MainActor
final class AppDependencies {
    static let shared = AppDependencies()
    static let preview = AppDependencies(inMemoryOnly: true)

    let modelContainer: ModelContainer
    let projectStore: ProjectStore

    private init(inMemoryOnly: Bool = ProcessInfo.processInfo.arguments.contains("UI_TESTING")) {
        do {
            let schema = Schema([
                StoredProject.self,
                StoredZone.self,
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemoryOnly
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.modelContainer = container
            self.projectStore = ProjectStore(container: container)
        } catch {
            fatalError("Failed to create app dependencies: \(error.localizedDescription)")
        }
    }
}
