//
//  ProjectCreationValidator.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Foundation

enum ProjectCreationValidator {
    static func canCreateProject(named name: String, boundary: ProjectBoundary?) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let boundary else {
            return false
        }

        return boundary.widthMeters > 0 && boundary.heightMeters > 0
    }
}
