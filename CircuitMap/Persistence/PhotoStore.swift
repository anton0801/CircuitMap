//
//  PhotoStore.swift
//  CircuitMap
//
//  Stores panel/route photos as JPEG files under Documents/photos and
//  loads them back by reference filename.
//

import UIKit

final class PhotoStore {
    static let shared = PhotoStore()
    private init() { createDirectoryIfNeeded() }

    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("photos", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory,
                                                     withIntermediateDirectories: true)
        }
    }

    /// Saves an image and returns its reference filename.
    func save(_ image: UIImage) -> String? {
        createDirectoryIfNeeded()
        let name = UUID().uuidString + ".jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = directory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    func load(_ ref: String) -> UIImage? {
        let url = directory.appendingPathComponent(ref)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(_ ref: String) {
        let url = directory.appendingPathComponent(ref)
        try? FileManager.default.removeItem(at: url)
    }
}
