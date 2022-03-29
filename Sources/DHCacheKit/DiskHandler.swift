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
        return try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(DiskHandler.containingFolder)
    }
    
    var localCacheFileExtension: String = ".cache"
    
    func fileURL<K, V>(for key: String, using cache: Cache<K, V>) -> URL? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let cacheURL = localCacheURL else { return nil }
        return cacheURL.appendingPathComponent(key + localCacheFileExtension)
    }
    
    func saveToDisk<K, V>(_: V.Type, with key: String, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let directoryURL = localCacheURL else { return false }
        guard let url = fileURL(for: key, using: cache) else { return false }
        
        do {
            let data = try JSONEncoder().encode(cache)
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url)
            return true
        } catch(let error) {
            print(error)
            return false
        }
    }
    
    func readEntryFromDisk<K, V>(using key: K, with cache: Cache<K, V>) -> Cache<K, V>.Entry? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let urlString = fileURL(for: "\(key)", using: cache)?.absoluteString else { return nil }
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
        guard let urlString = fileURL(for: "\(key)", using: cache)?.absoluteString else { return false }
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
            let filePaths = try fileManager.contentsOfDirectory(at: localCacheURL, includingPropertiesForKeys: nil)
            for filePath in filePaths {
                try fileManager.removeItem(at: filePath)
            }
            
            // Remove folder
            try fileManager.removeItem(at: localCacheURL)
            
            return true
        } catch {
            return false
        }
    }
}
