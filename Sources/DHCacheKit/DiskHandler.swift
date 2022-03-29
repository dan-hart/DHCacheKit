//
//  DiskHandler.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation
import FileKit

class DiskHandler: DiskHandling {
    static let containingFolder = "DHCache"
    
    var fileManager: FileManager {
        .default
    }
    
    var localCacheURL: URL? {
        return try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(DiskHandler.containingFolder)
    }
    
    var localCacheFileExtension: String = ".cache"
    
    func fileURL<K, V>(for key: K, using cache: Cache<K, V>) -> URL? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let cacheURL = localCacheURL else { return nil }
        let localCachePath = Path(cacheURL.absoluteString)
        if !localCachePath.exists {
            try? localCachePath.createDirectory()
        }
        return cacheURL.appendingPathComponent("\(key)" + localCacheFileExtension)
    }
    
    func saveToDisk<K, V>(_: V.Type, with key: K, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let urlString = fileURL(for: key, using: cache)?.absoluteString else { return false }
        let filePath = Path(urlString)
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: filePath)
            return filePath.exists
        } catch(let error) {
            print(error)
            return false
        }
    }
    
    func readEntryFromDisk<K, V>(using key: K, with cache: Cache<K, V>) -> Cache<K, V>.Entry? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let urlString = fileURL(for: key, using: cache)?.absoluteString else { return nil }
        let filePath = Path(urlString)
        
        do {
            let data = try Data(contentsOf: filePath.url)
            let cache = try JSONDecoder().decode(Cache<K, V>.self, from: data)
            return cache.entry(forKey: key)
        } catch {
            return nil
        }
    }
    
    func deleteFromDisk<K, V>(with key: K, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let urlString = fileURL(for: key, using: cache)?.absoluteString else { return false }
        let filePath = Path(urlString)
        
        do {
            try filePath.deleteFile()
            // Sucess if the file no longer exists
            return !filePath.exists
        } catch {
            return false
        }
    }
    
    func deleteAllOnDisk<K, V>(using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let localCacheURL = localCacheURL else { return false }
        
        do {
            let localCachePath = Path(localCacheURL.absoluteString)
            let cacheFiles = localCachePath.find(searchDepth: 1) { path in
                path.pathExtension == localCacheFileExtension
            }
            for file in cacheFiles {
                try file.deleteFile()
            }
            return true
        } catch {
            return false
        }
    }
}
