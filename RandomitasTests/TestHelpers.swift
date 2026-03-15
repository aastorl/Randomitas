//
//  TestHelpers.swift
//  RandomitasTests
//

import Foundation
@testable import Randomitas

func makeTestViewModel() -> RandomitasViewModel {
    let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    return RandomitasViewModel(coreDataStack: CoreDataStack.makeInMemory(), userDefaults: defaults)
}
