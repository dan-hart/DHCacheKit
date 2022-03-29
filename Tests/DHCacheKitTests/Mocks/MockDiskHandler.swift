//
//  MockDiskHandler.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

@testable import DHCacheKit
import Foundation

class MockDiskHandler: DiskHandling {
    var fileManager: FileManager = .default
    var localCacheURL: URL?
    var localCacheFileExtension: String = ".cacheMock"
    
    var mockFiles: [String: String] = [:]
    
    func fileURL<K, V>(for key: String, using cache: Cache<K, V>) -> URL? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        return URL(string: mockFiles["\(key)"])
    }
    
    func saveToDisk<K, V>(_: V.Type, with key: String, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        mockFiles["\(key)"] = UUID().uuidString
        return true
    }
    
    func readEntryFromDisk<K, V>(using key: K, with cache: Cache<K, V>) -> Cache<K, V>.Entry? where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        return nil
    }
    
    func deleteFromDisk<K, V>(with key: K, using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        mockFiles.removeValue(forKey: "\(key)")
        return true
    }
    
    func deleteAllOnDisk<K, V>(using cache: Cache<K, V>) -> Bool where K : Decodable, K : Encodable, K : Hashable, V : Decodable, V : Encodable {
        mockFiles.removeAll()
        return true
    }
}
