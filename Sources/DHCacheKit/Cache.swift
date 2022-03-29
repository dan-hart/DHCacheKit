//
//  Cache.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation
import FileKit
import SwifterSwift

public final class Cache<K: Codable & Hashable, V: Codable> {
    // MARK: - Private
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    private let keyTracker = KeyTracker()
    
    // MARK: - Public
    public let useLocalDisk: Bool
    public var diskHandler: DiskHandling?
    
    public init(
        dateProvider: @escaping () -> Date = Date.init,
        entryLifetime: TimeInterval = 60 * 60 * 24 * 90, // 90 days
        maximumEntryCount: Int = Int.max,
        useLocalDisk: Bool = false) {
            self.dateProvider = dateProvider
            self.entryLifetime = entryLifetime
            self.useLocalDisk = useLocalDisk
            wrapped.countLimit = maximumEntryCount
            wrapped.delegate = keyTracker
            if useLocalDisk {
                diskHandler = DiskHandler()
            } else {
                diskHandler = nil
            }
        }
    
    public func insert(_ value: V, forKey key: K) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
        diskHandler?.saveToDisk(V.self, with: "\(key)", using: self)
    }
    
    public func value<V: Codable>(forKey key: K) -> V? {
        var entry: Entry?
        
        if let memoryEntry = wrapped.object(forKey: WrappedKey(key)) {
            entry = memoryEntry
        } else {
            if useLocalDisk, let diskEntry = diskHandler?.readEntryFromDisk(using: key, with: self) {
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
        diskHandler?.deleteFromDisk(with: key, using: self)
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
// Make sure to use `if !useLocalDisk { return false }`

//extension Cache where K: Codable & Hashable, V: Codable {
//    public func fileURL(for key: K) -> URL? {
//        if !useLocalDisk { return nil }
//        guard let cacheURL = localCacheURL else { return nil }
//        let localCachePath = Path(cacheURL.absoluteString)
//        if !localCachePath.exists {
//            try? localCachePath.createDirectory()
//        }
//        return cacheURL.appendingPathComponent("\(key)" + localCacheFileExtension)
//    }
//
//    @discardableResult public func saveToDisk<V: Codable>(_: V.Type, with key: K) -> Bool {
//        if !useLocalDisk { return false }
//        guard let urlString = fileURL(for: key)?.absoluteString else { return false }
//        let filePath = Path(urlString)
//
//        do {
//            let data = try JSONEncoder().encode(self)
//            let file = File<Data>(path: filePath)
//            try file.write(data)
//            return file.exists
//        } catch(let error) {
//            print(error)
//            return false
//        }
//    }
//
//    /// call like `readEntryFromDisk(V.self, using: key)`
//    public func readEntryFromDisk<V: Codable>(_: V.Type, using key: K) -> Entry? {
//        if !useLocalDisk { return nil }
//        guard let urlString = fileURL(for: key)?.absoluteString else { return nil }
//        let filePath = Path(urlString)
//
//        do {
//            let file = File<Data>(path: filePath)
//            let data = try file.read()
//            let cache = try JSONDecoder().decode(Cache.self, from: data)
//            return cache.entry(forKey: key)
//        } catch {
//            return nil
//        }
//    }
//
//    @discardableResult public func deleteFromDisk(with key: K) -> Bool {
//        if !useLocalDisk { return false }
//        guard let urlString = fileURL(for: key)?.absoluteString else { return false }
//        let filePath = Path(urlString)
//
//        do {
//            try filePath.deleteFile()
//            // Sucess if the file no longer exists
//            return !filePath.exists
//        } catch {
//            return false
//        }
//    }
//
//    @discardableResult func clearAllOnDisk() -> Bool {
//        if !useLocalDisk { return false }
//        guard let localCacheURL = localCacheURL else { return false }
//
//        do {
//            let localCachePath = Path(localCacheURL.absoluteString)
//            let cacheFiles = localCachePath.find(searchDepth: 1) { path in
//                path.pathExtension == localCacheFileExtension
//            }
//            for file in cacheFiles {
//                try file.deleteFile()
//            }
//            return true
//        } catch {
//            return false
//        }
//    }
//}
