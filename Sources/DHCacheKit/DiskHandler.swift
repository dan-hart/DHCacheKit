//
//  DiskHandler.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation
import FileKit

class DiskHandler: DiskHandling {
    var size: String? {
        guard let localCacheURL = CacheHelper.localCacheURL else {
            return nil
        }

        return CacheHelper.fileManager.getDirectorySize(url: localCacheURL)
    }
    
    func fileURL<K, V>(for key: String, using cache: Cache<K, V>) -> URL? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let cacheURL = CacheHelper.localCacheURL else { return nil }
        return cacheURL.appendingPathComponent(key + CacheHelper.localCacheFileExtension)
    }
    
    func saveToDisk<K, V>(_: V.Type, with key: String, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let directoryURL = CacheHelper.localCacheURL else { return false }
        guard let url = fileURL(for: key, using: cache) else { return false }
        
        do {
            let data = try JSONEncoder().encode(cache)
            try CacheHelper.fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url)
            return true
        } catch(let error) {
            print(error)
            return false
        }
    }
    
    func readEntryFromDisk<K, V>(using key: K, with cache: Cache<K, V>) -> Cache<K, V>.Entry? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return nil }
        guard let url = fileURL(for: "\(key)", using: cache) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let cache = try JSONDecoder().decode(Cache<K, V>.self, from: data)
            return cache.entry(forKey: key)
        } catch {
            return nil
        }
    }
    
    func deleteFromDisk<K, V>(with key: K, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        if !cache.useLocalDisk { return false }
        guard let url = fileURL(for: "\(key)", using: cache) else { return false }
        
        do {
            try CacheHelper.fileManager.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}
