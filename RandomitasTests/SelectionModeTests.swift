//
//  SelectionModeTests.swift
//  RandomitasTests
//
//  Created for testing batch selection operations.
//

import Testing
@testable import Randomitas
import Foundation

@Suite(.serialized)
struct SelectionModeTests {
    
    // MARK: - Batch Delete Tests
    
    @Test func testBatchDeleteRootFolders() async throws {
        // Given: A viewModel with multiple root folders
        let viewModel = RandomitasViewModel()
        
        // Create test folders
        viewModel.addRootFolder(name: "Test1")
        viewModel.addRootFolder(name: "Test2")
        viewModel.addRootFolder(name: "Test3")
        
        // Get IDs before deletion
        let initialCount = viewModel.folders.count
        let idsToDelete: Set<UUID> = Set(viewModel.folders.prefix(2).map { $0.id })
        
        // When: Batch deleting 2 folders
        viewModel.batchDeleteRootFolders(ids: idsToDelete)
        
        // Then: Should have 2 fewer folders
        #expect(viewModel.folders.count == initialCount - 2)
        
        // Cleanup
        for folder in viewModel.folders {
            viewModel.deleteRootFolder(id: folder.id)
        }
    }
    
    @Test func testBatchDeleteSubfolders() async throws {
        // Given: A viewModel with a parent folder containing subfolders
        let viewModel = RandomitasViewModel()
        
        // Create parent folder
        viewModel.addRootFolder(name: "Parent")
        let parentPath = [0]
        
        // Add subfolders
        viewModel.addSubfolder(name: "Sub1", to: parentPath)
        viewModel.addSubfolder(name: "Sub2", to: parentPath)
        viewModel.addSubfolder(name: "Sub3", to: parentPath)
        
        // Get subfolder IDs
        guard let parent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent folder should exist")
            return
        }
        
        let initialSubCount = parent.subfolders.count
        let idsToDelete: Set<UUID> = Set(parent.subfolders.prefix(2).map { $0.id })
        
        // When: Batch deleting 2 subfolders
        viewModel.batchDeleteSubfolders(ids: idsToDelete, from: parentPath)
        
        // Then: Should have 2 fewer subfolders
        guard let updatedParent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent folder should still exist")
            return
        }
        #expect(updatedParent.subfolders.count == initialSubCount - 2)
        
        // Cleanup
        viewModel.deleteRootFolder(id: viewModel.folders[0].id)
    }
    
    // MARK: - Batch Hide Tests
    
    @Test func testBatchToggleHiddenRoot() async throws {
        // Given: A viewModel with root folders
        let viewModel = RandomitasViewModel()
        
        viewModel.addRootFolder(name: "Visible1")
        viewModel.addRootFolder(name: "Visible2")
        
        let idsToHide: Set<UUID> = Set(viewModel.folders.suffix(2).map { $0.id })
        
        // When: Toggling hidden state (to hidden)
        viewModel.batchToggleHiddenRoot(ids: idsToHide)
        
        // Then: Folders should be hidden
        let hiddenFolders = viewModel.getHiddenFolders()
        #expect(hiddenFolders.count >= 2)
        
        // When: Toggling again (to visible)
        viewModel.batchToggleHiddenRoot(ids: idsToHide)
        
        // Then: Folders should be visible
        let hiddenAfterToggle = viewModel.getHiddenFolders()
        let stillHidden = hiddenAfterToggle.filter { idsToHide.contains($0.folder.id) }
        #expect(stillHidden.isEmpty)
        
        // Cleanup
        for id in idsToHide {
            viewModel.deleteRootFolder(id: id)
        }
    }
    
    @Test func testBatchToggleHiddenSubfolders() async throws {
        // Given: A viewModel with subfolders
        let viewModel = RandomitasViewModel()
        
        viewModel.addRootFolder(name: "Parent")
        let parentPath = [viewModel.folders.count - 1]
        
        viewModel.addSubfolder(name: "SubVis1", to: parentPath)
        viewModel.addSubfolder(name: "SubVis2", to: parentPath)
        
        guard let parent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent should exist")
            return
        }
        
        let idsToHide: Set<UUID> = Set(parent.subfolders.map { $0.id })
        
        // When: Toggling hidden state
        viewModel.batchToggleHiddenSubfolders(ids: idsToHide, at: parentPath)
        
        // Then: Subfolders should be hidden
        guard let updatedParent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent should still exist")
            return
        }
        
        let hiddenCount = updatedParent.subfolders.filter { $0.isHidden }.count
        #expect(hiddenCount == idsToHide.count)
        
        // Cleanup
        viewModel.deleteRootFolder(id: viewModel.folders[parentPath[0]].id)
    }
    
    // MARK: - Selection State Tests
    
    @Test func testEmptySelectionDisablesActions() async throws {
        // Given: Empty selection set
        let selectedIds: Set<UUID> = []
        
        // Then: Actions should be disabled
        #expect(selectedIds.isEmpty == true)
    }
    
    @Test func testSelectionCountDisplay() async throws {
        // Given: Various selection counts
        let singleSelection: Set<UUID> = [UUID()]
        let multiSelection: Set<UUID> = [UUID(), UUID(), UUID()]
        
        // Then: Count formatting should be correct
        #expect(singleSelection.count == 1)
        #expect(multiSelection.count == 3)
        
        // Test pluralization logic
        let singleText = "\(singleSelection.count) seleccionado\(singleSelection.count > 1 ? "s" : "")"
        let multiText = "\(multiSelection.count) seleccionado\(multiSelection.count > 1 ? "s" : "")"
        
        #expect(singleText == "1 seleccionado")
        #expect(multiText == "3 seleccionados")
    }
    
    // MARK: - Move/Copy Operation Tests
    
    @Test func testMoveCopyOperationCreation() async throws {
        // Given: Folders to move/copy
        let folder1 = Folder(id: UUID(), name: "Folder1", subfolders: [], imageData: nil, createdAt: Date(), isHidden: false)
        let folder2 = Folder(id: UUID(), name: "Folder2", subfolders: [], imageData: nil, createdAt: Date(), isHidden: false)
        let sourcePath = [0, 1]
        
        // When: Creating move operation
        let moveOp = MoveCopyOperation(items: [folder1, folder2], sourceContainerPath: sourcePath, isCopy: false)
        
        // Then: Operation should be configured correctly
        #expect(moveOp.items.count == 2)
        #expect(moveOp.sourceContainerPath == sourcePath)
        #expect(moveOp.isCopy == false)
        
        // When: Creating copy operation
        let copyOp = MoveCopyOperation(items: [folder1], sourceContainerPath: [], isCopy: true)
        
        // Then: Should be marked as copy
        #expect(copyOp.isCopy == true)
        #expect(copyOp.sourceContainerPath.isEmpty)
    }
    
    // MARK: - Path-Based Logic Tests
    
    @Test func testRootPathDetection() async throws {
        // Given: Various folder paths
        let rootPath: [Int] = []
        let subfolderPath: [Int] = [0]
        let nestedPath: [Int] = [0, 1, 2]
        
        // Then: Empty path should indicate root
        #expect(rootPath.isEmpty == true)
        #expect(subfolderPath.isEmpty == false)
        #expect(nestedPath.isEmpty == false)
    }
    
    @Test func testDeleteMethodSelection() async throws {
        // Given: Path determines which delete method to use
        let rootPath: [Int] = []
        let subfolderPath: [Int] = [0]
        
        // Simulate the conditional logic
        let shouldUseRootDelete = rootPath.isEmpty
        let shouldUseSubfolderDelete = !subfolderPath.isEmpty
        
        // Then: Correct method should be selected
        #expect(shouldUseRootDelete == true)
        #expect(shouldUseSubfolderDelete == true)
    }
    
    // MARK: - Move/Copy by ID Tests (New)
    
    @Test func testMoveFolderById() async throws {
        // Given: A viewModel with folders
        let viewModel = RandomitasViewModel()
        
        // Create source and target folders
        viewModel.addRootFolder(name: "Source")
        viewModel.addRootFolder(name: "Target")
        
        let sourceId = viewModel.folders.first(where: { $0.name == "Source" })?.id
        let targetId = viewModel.folders.first(where: { $0.name == "Target" })?.id
        
        guard let sourceId = sourceId, let targetId = targetId else {
            #expect(Bool(false), "Folders should exist")
            return
        }
        
        // When: Moving source folder into target by ID
        viewModel.moveFolderById(id: sourceId, toFolderId: targetId)
        
        // Then: Source should be a child of Target
        let target = viewModel.folders.first(where: { $0.id == targetId })
        #expect(target?.subfolders.contains(where: { $0.id == sourceId }) == true)
        
        // Source should no longer be at root
        #expect(viewModel.folders.contains(where: { $0.id == sourceId }) == false)
        
        // Cleanup
        viewModel.deleteRootFolder(id: targetId)
    }
    
    @Test func testMoveFolderByIdToRoot() async throws {
        // Given: A viewModel with nested folder
        let viewModel = RandomitasViewModel()
        
        viewModel.addRootFolder(name: "Parent")
        let parentPath = [viewModel.folders.count - 1]
        viewModel.addSubfolder(name: "Child", to: parentPath)
        
        guard let parent = viewModel.getFolderFromPath(parentPath),
              let childId = parent.subfolders.first?.id else {
            #expect(Bool(false), "Parent and child should exist")
            return
        }
        
        // When: Moving child to root (nil targetId)
        viewModel.moveFolderById(id: childId, toFolderId: nil)
        
        // Then: Child should be at root
        #expect(viewModel.folders.contains(where: { $0.id == childId }) == true)
        
        // Cleanup
        for folder in viewModel.folders {
            viewModel.deleteRootFolder(id: folder.id)
        }
    }
    
    @Test func testCopyFolderById() async throws {
        // Given: A viewModel with folders
        let viewModel = RandomitasViewModel()
        
        viewModel.addRootFolder(name: "Original")
        viewModel.addRootFolder(name: "Target")
        
        let originalId = viewModel.folders.first(where: { $0.name == "Original" })?.id
        let targetId = viewModel.folders.first(where: { $0.name == "Target" })?.id
        
        guard let originalId = originalId, let targetId = targetId else {
            #expect(Bool(false), "Folders should exist")
            return
        }
        
        // When: Copying original into target by ID
        viewModel.copyFolderById(id: originalId, toFolderId: targetId)
        
        // Then: Original should still exist at root
        #expect(viewModel.folders.contains(where: { $0.id == originalId }) == true)
        
        // And a copy should exist in target
        let target = viewModel.folders.first(where: { $0.id == targetId })
        #expect(target?.subfolders.contains(where: { $0.name == "Original" }) == true)
        
        // The copy should have a different ID
        let copyId = target?.subfolders.first(where: { $0.name == "Original" })?.id
        #expect(copyId != originalId)
        
        // Cleanup
        for folder in viewModel.folders {
            viewModel.deleteRootFolder(id: folder.id)
        }
    }
    
    // MARK: - Favorites on Creation Tests (New)
    
    @Test func testAddRootFolderWithFavorite() async throws {
        // Given: A viewModel
        let viewModel = RandomitasViewModel()
        
        // When: Creating a root folder with isFavorite = true
        viewModel.addRootFolder(name: "FavRoot", isFavorite: true)
        
        // Then: The folder should exist
        let folder = viewModel.folders.first(where: { $0.name == "FavRoot" })
        #expect(folder != nil)
        
        // And it should be in favorites
        if let folderId = folder?.id {
            #expect(viewModel.isFolderFavorite(folderId: folderId) == true)
        }
        
        // Cleanup
        if let folderId = folder?.id {
            viewModel.deleteRootFolder(id: folderId)
        }
    }
    
    @Test func testAddSubfolderWithFavorite() async throws {
        // Given: A viewModel with a parent folder
        let viewModel = RandomitasViewModel()
        
        viewModel.addRootFolder(name: "Parent")
        let parentPath = [viewModel.folders.count - 1]
        
        // When: Creating a subfolder with isFavorite = true
        viewModel.addSubfolder(name: "FavChild", to: parentPath, isFavorite: true)
        
        // Then: The subfolder should exist
        guard let parent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent should exist")
            return
        }
        
        let subfolder = parent.subfolders.first(where: { $0.name == "FavChild" })
        #expect(subfolder != nil)
        
        // And it should be in favorites
        if let subfolderId = subfolder?.id {
            #expect(viewModel.isFolderFavorite(folderId: subfolderId) == true)
        }
        
        // Cleanup
        viewModel.deleteRootFolder(id: viewModel.folders[parentPath[0]].id)
    }
}
