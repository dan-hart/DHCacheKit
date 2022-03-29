//
//  CacheOnDiskTests.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

@testable import DHCacheKit
import XCTest
import FileKit

class CacheOnDiskTests: XCTestCase {
    func testInit() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        XCTAssertNotNil(cache)
        cache.diskHandler = MockDiskHandler()
        XCTAssertNotNil(cache.diskHandler)
    }
    
    func testSaveOnDisk() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.diskHandler = MockDiskHandler()
        let didSave = cache.diskHandler?.saveToDisk([String].self, with: "Greeting", using: cache) ?? false
        XCTAssertTrue(didSave)
    }
    
    func testDeleteFromDisk() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.diskHandler = MockDiskHandler()
        cache.insert(["Hello", "World"], forKey: "Greeting")
        let entry = cache.entry(forKey: "Greeting")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.value, ["Hello", "World"])
        
        cache.removeValue(forKey: "Greeting")
        XCTAssertEqual((cache.diskHandler as? MockDiskHandler)?.mockFiles.count, 0)
    }
    
    func testDeleteAllFromDisk() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.diskHandler = MockDiskHandler()
        cache.insert(["Hello", "World"], forKey: "Greeting")
        cache.insert(["1", "2", "3"], forKey: "Count")
        XCTAssertEqual((cache.diskHandler as? MockDiskHandler)?.mockFiles.count, 2)
        
        cache.diskHandler?.deleteAllOnDisk(using: cache)
        XCTAssertEqual((cache.diskHandler as? MockDiskHandler)?.mockFiles.count, 0)
    }
}
