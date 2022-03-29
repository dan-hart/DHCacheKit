//
//  DiskHandling.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation

public protocol DiskHandling {
    var fileManager: FileManager { get }
    var localCacheURL: URL? { get }
    var localCacheFileExtension: String { get }
    
    func fileURL<K: Codable & Hashable, V: Codable>(for key: K, using cache: Cache<K, V>) -> URL?
    @discardableResult func saveToDisk<K: Codable & Hashable, V: Codable>(_: V.Type, with key: K, using cache: Cache<K, V>) -> Bool
    func readEntryFromDisk<K: Codable & Hashable, V: Codable>(using key: K, with cache: Cache<K, V>) -> Cache<K, V>.Entry?
    @discardableResult func deleteFromDisk<K: Codable & Hashable, V: Codable>(with key: K, using cache: Cache<K, V>) -> Bool
    @discardableResult func deleteAllOnDisk<K: Codable & Hashable, V: Codable>(using cache: Cache<K, V>) -> Bool
}
