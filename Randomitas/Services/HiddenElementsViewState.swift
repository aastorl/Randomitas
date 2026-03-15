//
//  HiddenElementsViewState.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct HiddenElementsViewState {
    private var state: [String: Bool] = [:]

    mutating func isShowingHiddenElements(for path: [Int]) -> Bool {
        let key = path.map(String.init).joined(separator: "_")
        return state[key] ?? false
    }

    mutating func setShowingHiddenElements(_ showing: Bool, for path: [Int]) {
        let key = path.map(String.init).joined(separator: "_")
        state[key] = showing
    }
}
