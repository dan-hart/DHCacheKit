//
//  Cache.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation

public final class Cache<K: Codable & Hashable, V: Codable> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    private let keyTracker = KeyTracker()

    public init(
        dateProvider: @escaping () -> Date = Date.init,
        entryLifetime: TimeInterval = 60 * 60 * 24 * 30, // 30 days
        maximumEntryCount: Int = Int.max) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
    }

    public func insert(_ value: V, forKey key: K) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
        if let filePath = try? saveToDisk(with: "\(key)") {
            print("Inserted value for \(key) at \(filePath.absoluteURL)")
        }
    }

    public func value<V: Codable>(forKey key: K) -> V? {
        var entry: Entry?
        
        if let memoryEntry = wrapped.object(forKey: WrappedKey(key)) {
            entry = memoryEntry
        } else {
            if let diskEntry = try? readFromDisk(V.self, with: key) {
                entry = diskEntry
            }
        }
        
        guard let e = entry, dateProvider() < e.expirationDate else {
            // Discard values that have expired
            removeValue(forKey: key)
            return nil
        }

        return entry?.value as? V
    }

    public func removeValue(forKey key: K) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
}

// MARK: - Cache Subscript
extension Cache {
    public subscript(key: K) -> V? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}

// MARK: - Cache.WrappedKey
extension Cache {
    public final class WrappedKey: NSObject {
        let key: K

        init(_ key: K) { self.key = key }

        public override var hash: Int { return key.hashValue }

        public override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
}

// MARK: - Cache.Entry
extension Cache {
    public final class Entry {
        let key: K
        let value: V
        let expirationDate: Date

        init(key: K, value: V, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

// MARK: - Cache.KeyTracker
extension Cache {
    public final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<K>()

        public func cache(_: NSCache<AnyObject, AnyObject>,
                   willEvictObject obj: Any)
        {
            guard let entry = obj as? Entry else {
                return
            }

            keys.remove(entry.key)
        }
    }
}

// MARK: - Cache Codable
extension Cache.Entry: Codable where K: Codable, V: Codable {}

extension Cache {
    public func entry(forKey key: K) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard Date() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }

        return entry
    }

    public func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
}

extension Cache: Codable where K: Codable, V: Codable {
    convenience public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
}

// MARK: - Cache Save To Disk
extension Cache where K: Codable & Hashable, V: Codable {
    @discardableResult
    public func saveToDisk(
        with name: String,
        using fileManager: FileManager = .default
    ) throws -> URL? {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
        return fileURL
    }

    public func readFromDisk<Value: Codable>(
        _: Value.Type,
        with name: K,
        using fileManager: FileManager = .default
    ) throws -> Entry? {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent("\(name).cache")
        let data = try Data(contentsOf: fileURL)
        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            return cache.entry(forKey: name)
        } catch {
            print(error)
            return nil
        }
    }

    @discardableResult
    public func deleteFromDisk(
        with name: String,
        using fileManager: FileManager = .default
    ) throws -> URL? {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        try fileManager.removeItem(at: fileURL)
        return fileURL
    }
}
