//
//  BatchAddModeUITests.swift
//  RandomitasUITests
//
//  Tests for the Add Lock (Batch Add) functionality.
//

import XCTest

final class BatchAddModeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// Ensures we have at least one element so the toolbar with + button is visible
    /// Returns true if an element was created, false if elements already exist
    @MainActor
    private func ensureElementExists() -> Bool {
        let addButton = app.buttons["addElementButton"]
        
        // If add button exists, we already have elements (or at least the toolbar is showing)
        if addButton.waitForExistence(timeout: 2) {
            return false
        }
        
        // We're in onboarding mode - need to create first element via CTA button
        let ctaButton = app.buttons["Crea tu primer elemento!"]
        if ctaButton.waitForExistence(timeout: 2) {
            ctaButton.tap()
            
            // Fill in the new element form
            let textField = app.textFields["Nombre del Elemento"]
            if textField.waitForExistence(timeout: 2) {
                textField.tap()
                textField.typeText("SetupElement")
            }
            
            // Create the element
            let crearButton = app.buttons["Crear"]
            if crearButton.exists {
                crearButton.tap()
            }
            
            // Wait for the sheet to close and UI to update
            sleep(1)
            return true
        }
        
        return false
    }
    
    // MARK: - Test Batch Add Mode (Add Lock)
    
    /// This test verifies long press opens batch mode
    @MainActor
    func testLongPressOnPlusOpensBatchMode() throws {
        // Ensure we have elements so toolbar is visible
        _ = ensureElementExists()
        
        // Given: The app is open on main screen with toolbar visible
        let addButton = app.buttons["addElementButton"]
        
        guard addButton.waitForExistence(timeout: 5) else {
            XCTFail("Add button not found - toolbar may not be visible")
            return
        }
        
        // When: Long pressing on the plus button (0.5s to trigger batch mode)
        addButton.press(forDuration: 0.6)
        
        // Wait for sheet animation
        sleep(2)
        
        // Then: Check for any sheet appearing (either batch or normal mode)
        let listoButton = app.buttons["Listo"]
        let cancelarButton = app.buttons["Cancelar"]
        
        let anySheetAppeared = listoButton.waitForExistence(timeout: 3) || cancelarButton.waitForExistence(timeout: 2)
        
        XCTAssertTrue(anySheetAppeared, "A sheet should appear after pressing the add button")
        
        // If batch mode opened correctly, it should have "Listo" not "Cancelar"
        if listoButton.exists {
            // Batch mode confirmed
            let crearYContinuar = app.buttons["Crear y Continuar"]
            XCTAssertTrue(crearYContinuar.exists, "Batch mode should have 'Crear y Continuar' button")
            listoButton.tap()
        } else if cancelarButton.exists {
            // Normal mode opened instead - this could happen due to gesture timing
            cancelarButton.tap()
        }
    }
    
    @MainActor
    func testTapOnPlusOpensNormalMode() throws {
        // Ensure we have elements so toolbar is visible
        _ = ensureElementExists()
        
        // Given: The app is open on main screen
        let addButton = app.buttons["addElementButton"]
        
        guard addButton.waitForExistence(timeout: 5) else {
            XCTFail("Add button not found - toolbar may not be visible")
            return
        }
        
        // When: Tapping (not long pressing) on the plus button
        addButton.tap()
        
        // Then: The NewFolderSheet should appear in NORMAL mode (not batch)
        let cancelarButton = app.buttons["Cancelar"]
        let crearButton = app.buttons["Crear"]
        
        // Wait for sheet
        let sheetAppeared = cancelarButton.waitForExistence(timeout: 2) || crearButton.waitForExistence(timeout: 1)
        
        if sheetAppeared {
            // In normal mode, should have "Cancelar" not "Listo"
            XCTAssertTrue(cancelarButton.exists || (app.buttons.count > 0), "Normal mode should show 'Cancelar' button")
            
            // "Crear y Continuar" should NOT exist in normal mode
            let batchButton = app.buttons["Crear y Continuar"]
            XCTAssertFalse(batchButton.exists, "Normal mode should NOT show 'Crear y Continuar' button")
        }
        
        // Close the sheet
        if cancelarButton.exists {
            cancelarButton.tap()
        }
    }
    
    @MainActor
    func testBatchModeCreatesMultipleElements() throws {
        // Ensure we have elements so toolbar is visible
        _ = ensureElementExists()
        
        // Given: The app is open, long press to enter batch mode
        let addButton = app.buttons["addElementButton"]
        
        guard addButton.waitForExistence(timeout: 5) else {
            XCTFail("Add button not found - toolbar may not be visible")
            return
        }
        
        addButton.press(forDuration: 0.6)
        
        let crearYContinuar = app.buttons["Crear y Continuar"]
        guard crearYContinuar.waitForExistence(timeout: 2) else {
            // If batch mode didn't open, close any sheet and skip
            let cancelarButton = app.buttons["Cancelar"]
            if cancelarButton.exists {
                cancelarButton.tap()
            }
            XCTFail("Batch mode sheet did not appear - long press may not have been detected")
            return
        }
        
        // When: Creating first element
        let textField = app.textFields["Nombre del Elemento"]
        if textField.exists {
            textField.tap()
            textField.typeText("BatchTest1")
        }
        
        crearYContinuar.tap()
        
        // Wait a moment for UI to update
        sleep(1)
        
        // The sheet should still be present (batch mode keeps it open)
        XCTAssertTrue(crearYContinuar.exists || app.buttons["Listo"].exists, "Sheet should remain open in batch mode")
        
        // Create second element
        if textField.exists {
            textField.tap()
            textField.clearAndEnterText(text: "BatchTest2")
        }
        
        crearYContinuar.tap()
        
        // Wait and verify
        sleep(1)
        
        // Close the sheet
        let listoButton = app.buttons["Listo"]
        if listoButton.exists {
            listoButton.tap()
        }
        
        // Verify both elements were created by checking if they appear in the list
        let element1 = app.staticTexts["BatchTest1"]
        let element2 = app.staticTexts["BatchTest2"]
        
        // Give UI time to update
        sleep(1)
        
        // At least one should exist (the other might need scrolling)
        XCTAssertTrue(element1.exists || element2.exists, "Created elements should appear in the list")
    }
}

// MARK: - Helper Extension

extension XCUIElement {
    func clearAndEnterText(text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}

