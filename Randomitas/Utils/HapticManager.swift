//
//  HapticManager.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/01/2026.
//

internal import UIKit

/// Gestor centralizado de respuestas hápticas de la app
enum HapticManager {
    
    // MARK: - Respuestas de Impacto
    
    /// Impacto ligero - para toques sutiles de botones (navegación, interruptores)
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Impacto medio - para botones principales (crear, confirmar, aleatorio)
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Impacto fuerte - para acciones importantes o destructivas (eliminar)
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Respuestas de Notificación
    
    /// Notificación de éxito - para operaciones exitosas (elemento creado, edición guardada)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Notificación de advertencia - para advertencias o acciones preventivas
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Notificación de error - para estados de error
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Respuestas de Selección
    
    /// Cambio de selección - para pickers, toggles y selección de elementos
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Patrones Especiales
    
    /// Doble impacto ligero - para entrar al modo selección múltiple (dos toques rápidos)
    static func doubleLightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
    }
}
