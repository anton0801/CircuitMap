//
//  PersistenceManager.swift
//  CircuitMap
//
//  JSON encode/decode of AppData to the Documents directory, with a
//  lightweight debounced save.
//

import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()
    private init() {}

    private let filename = "circuitmap_data.json"
    private var saveWorkItem: DispatchWorkItem?

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(filename)
    }

    func load() -> AppData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AppData.self, from: data)
    }

    /// Debounced save (coalesces rapid mutations).
    func save(_ data: AppData) {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.write(data)
        }
        saveWorkItem = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// Immediate, synchronous write (used on backgrounding).
    func flush(_ data: AppData) {
        saveWorkItem?.cancel()
        write(data)
    }

    private func write(_ data: AppData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    /// Encoded copy for backup/export.
    func exportData(_ data: AppData) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(data)
    }
}
