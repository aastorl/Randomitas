//
//  FavoritesAndPathTests.swift
//  RandomitasTests
//
//  Tests for findPathById and favorites refactor (UUID-based).
//

import Testing
@testable import Randomitas
import Foundation

@Suite(.serialized)
struct FavoritesAndPathTests {
    
    // MARK: - findPathById Tests
    
    @Test func testFindPathByIdRootFolder() async throws {
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "FindMe")
        
        let folder = viewModel.folders.first(where: { $0.name == "FindMe" })
        guard let folderId = folder?.id else {
            #expect(Bool(false), "Folder should exist")
            return
        }
        
        let path = viewModel.findPathById(folderId)
        #expect(path != nil, "Path should be found")
        
        // Path should point to the correct folder
        if let path = path {
            let found = viewModel.getFolderFromPath(path)
            #expect(found?.id == folderId)
        }
        
        // Cleanup
        viewModel.deleteRootFolder(id: folderId)
    }
    
    @Test func testFindPathByIdNestedFolder() async throws {
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "Parent")
        let parentPath = [viewModel.folders.count - 1]
        viewModel.addSubfolder(name: "Child", to: parentPath)
        
        guard let parent = viewModel.getFolderFromPath(parentPath) else {
            #expect(Bool(false), "Parent should exist")
            return
        }
        
        let childId = parent.subfolders.first(where: { $0.name == "Child" })?.id
        guard let childId = childId else {
            #expect(Bool(false), "Child should exist")
            return
        }
        
        let path = viewModel.findPathById(childId)
        #expect(path != nil, "Path should be found for nested folder")
        
        if let path = path {
            let found = viewModel.getFolderFromPath(path)
            #expect(found?.id == childId)
            #expect(found?.name == "Child")
        }
        
        // Cleanup
        viewModel.deleteRootFolder(id: viewModel.folders[parentPath[0]].id)
    }
    
    @Test func testFindPathByIdNonExistent() async throws {
        let viewModel = makeTestViewModel()
        
        let fakeId = UUID()
        let path = viewModel.findPathById(fakeId)
        
        #expect(path == nil, "Should return nil for non-existent folder")
    }
    
    @Test func testFindPathByIdAfterReorder() async throws {
        // This tests the core bug fix: paths should update when elements are added/deleted
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "AAA")
        viewModel.addRootFolder(name: "BBB")
        viewModel.addRootFolder(name: "CCC")
        
        let bbbId = viewModel.folders.first(where: { $0.name == "BBB" })?.id
        let cccId = viewModel.folders.first(where: { $0.name == "CCC" })?.id
        
        guard let bbbId = bbbId, let cccId = cccId else {
            #expect(Bool(false), "Folders should exist")
            return
        }
        
        // Delete AAA - this shifts BBB and CCC indices
        let aaaId = viewModel.folders.first(where: { $0.name == "AAA" })?.id
        if let aaaId = aaaId {
            viewModel.deleteRootFolder(id: aaaId)
        }
        
        // findPathById should still find BBB and CCC at their new indices
        let bbbPath = viewModel.findPathById(bbbId)
        let cccPath = viewModel.findPathById(cccId)
        
        #expect(bbbPath != nil, "BBB should still be findable after deletion")
        #expect(cccPath != nil, "CCC should still be findable after deletion")
        
        if let bbbPath = bbbPath {
            let found = viewModel.getFolderFromPath(bbbPath)
            #expect(found?.name == "BBB")
        }
        
        if let cccPath = cccPath {
            let found = viewModel.getFolderFromPath(cccPath)
            #expect(found?.name == "CCC")
        }
        
        // Cleanup
        for folder in viewModel.folders {
            viewModel.deleteRootFolder(id: folder.id)
        }
    }
    
    // MARK: - Favorites Persistence Tests
    
    @Test func testFavoritesSurviveAfterDeletion() async throws {
        // Core test: favorites should NOT disappear when other elements are deleted
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "WillDelete")
        viewModel.addRootFolder(name: "WillKeep")
        viewModel.addRootFolder(name: "IsFavorite")
        
        // Mark "IsFavorite" as favorite
        let favFolder = viewModel.folders.first(where: { $0.name == "IsFavorite" })
        guard let favFolder = favFolder, let favPath = viewModel.findPathById(favFolder.id) else {
            #expect(Bool(false), "Favorite folder should exist")
            return
        }
        
        viewModel.toggleFolderFavorite(folder: favFolder, path: favPath)
        #expect(viewModel.isFolderFavorite(folderId: favFolder.id) == true)
        
        // Delete "WillDelete" - this shifts indices
        if let deleteId = viewModel.folders.first(where: { $0.name == "WillDelete" })?.id {
            viewModel.deleteRootFolder(id: deleteId)
        }
        
        // Favorite should STILL be accessible
        #expect(viewModel.isFolderFavorite(folderId: favFolder.id) == true)
        
        // findPathById should still locate it
        let newPath = viewModel.findPathById(favFolder.id)
        #expect(newPath != nil, "Favorite should still be findable after other folder was deleted")
        
        if let newPath = newPath {
            let found = viewModel.getFolderFromPath(newPath)
            #expect(found?.name == "IsFavorite")
        }
        
        // Cleanup
        for folder in viewModel.folders {
            viewModel.deleteRootFolder(id: folder.id)
        }
    }
    
    @Test func testHiddenRemovesFavorite() async throws {
        // When hiding a folder, it should be removed from favorites
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "TestHideFav")
        
        let folder = viewModel.folders.first(where: { $0.name == "TestHideFav" })
        guard let folder = folder, let path = viewModel.findPathById(folder.id) else {
            #expect(Bool(false), "Folder should exist")
            return
        }
        
        // Add to favorites
        viewModel.toggleFolderFavorite(folder: folder, path: path)
        #expect(viewModel.isFolderFavorite(folderId: folder.id) == true)
        
        // Hide the folder
        viewModel.toggleFolderHidden(folder: folder, path: path)
        
        // Should no longer be a favorite
        #expect(viewModel.isFolderFavorite(folderId: folder.id) == false)
        
        // Cleanup
        viewModel.deleteRootFolder(id: folder.id)
    }
    
    @Test func testCannotFavoriteHiddenFolder() async throws {
        let viewModel = makeTestViewModel()
        
        viewModel.addRootFolder(name: "HiddenFirst")
        
        let folder = viewModel.folders.first(where: { $0.name == "HiddenFirst" })
        guard let folder = folder, let path = viewModel.findPathById(folder.id) else {
            #expect(Bool(false), "Folder should exist")
            return
        }
        
        // Hide first
        viewModel.toggleFolderHidden(folder: folder, path: path)
        
        // Try to favorite - should be blocked
        let updatedFolder = viewModel.getFolderFromPath(viewModel.findPathById(folder.id)!)!
        viewModel.toggleFolderFavorite(folder: updatedFolder, path: viewModel.findPathById(folder.id)!)
        
        #expect(viewModel.isFolderFavorite(folderId: folder.id) == false, "Hidden folder should not be favoritable")
        
        // Cleanup
        viewModel.deleteRootFolder(id: folder.id)
    }
    
    // MARK: - Deep Nesting Tests
    
    @Test func testFindPathByIdDeeplyNested() async throws {
        let viewModel = makeTestViewModel()
        
        // Create: Root > Level1 > Level2 > Level3
        viewModel.addRootFolder(name: "Root")
        let rootPath = [viewModel.folders.count - 1]
        
        viewModel.addSubfolder(name: "Level1", to: rootPath)
        let level1Path = rootPath + [0]
        
        viewModel.addSubfolder(name: "Level2", to: level1Path)
        let level2Path = level1Path + [0]
        
        viewModel.addSubfolder(name: "Level3", to: level2Path)
        
        // Get Level3 ID
        guard let level2 = viewModel.getFolderFromPath(level2Path),
              let level3Id = level2.subfolders.first?.id else {
            #expect(Bool(false), "Deep folders should exist")
            return
        }
        
        // findPathById should find deeply nested element
        let foundPath = viewModel.findPathById(level3Id)
        #expect(foundPath != nil, "Should find deeply nested folder")
        
        if let foundPath = foundPath {
            let found = viewModel.getFolderFromPath(foundPath)
            #expect(found?.name == "Level3")
        }
        
        // Cleanup
        viewModel.deleteRootFolder(id: viewModel.folders[rootPath[0]].id)
    }
}
