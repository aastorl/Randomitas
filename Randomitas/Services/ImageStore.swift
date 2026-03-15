//
//  ImageStore.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import os

/// Stores images on disk and keeps a memory cache of decoded data.
@MainActor
final class ImageStore {
    static let shared = ImageStore()

    private let logger = Logger(subsystem: "Randomitas", category: "ImageStore")
    private let cache = NSCache<NSString, NSData>()
    private let prefix = "imgref:"

    private var baseURL: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("FolderImages", isDirectory: true)
    }

    func encodeReference(_ reference: String) -> Data {
        Data((prefix + reference).utf8)
    }

    func decodeReference(_ data: Data) -> String? {
        guard let str = String(data: data, encoding: .utf8), str.hasPrefix(prefix) else { return nil }
        return String(str.dropFirst(prefix.count))
    }

    func saveImageData(_ data: Data) -> String? {
        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let filename = UUID().uuidString + ".img"
            let url = baseURL.appendingPathComponent(filename)
            try data.write(to: url, options: [.atomic])
            cache.setObject(data as NSData, forKey: filename as NSString)
            return filename
        } catch {
            logger.error("Error saving image data: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func loadImageData(reference: String) -> Data? {
        if let cached = cache.object(forKey: reference as NSString) {
            return cached as Data
        }
        let url = baseURL.appendingPathComponent(reference)
        guard let data = try? Data(contentsOf: url) else { return nil }
        cache.setObject(data as NSData, forKey: reference as NSString)
        return data
    }

    func deleteImage(reference: String) {
        let url = baseURL.appendingPathComponent(reference)
        do {
            try FileManager.default.removeItem(at: url)
            cache.removeObject(forKey: reference as NSString)
        } catch {
            logger.error("Error deleting image reference: \(error.localizedDescription, privacy: .public)")
        }
    }
}
