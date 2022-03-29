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
    func testWriteFile() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.insert(["1", "2", "3"], forKey: "Numbers")
        guard let fileURL = cache.diskHandler?.fileURL(for: "Numbers", using: cache) else { return XCTFail("Could not get URL") }
        XCTAssertTrue(Path(url: fileURL)?.exists ?? false)
        
        // Clean up
        cache.diskHandler?.deleteAllOnDisk(using: cache)
    }
    
    func testReadFile() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.insert(["1", "2", "3"], forKey: "Numbers")
        guard let fileURL = cache.diskHandler?.fileURL(for: "Numbers", using: cache) else { return XCTFail("Could not get URL") }
        XCTAssertTrue(Path(url: fileURL)?.exists ?? false)
        
        let entry = cache.diskHandler?.readEntryFromDisk(using: "Numbers", with: cache)
        XCTAssertEqual(entry?.value, ["1", "2", "3"])
        
        // Clean up
        cache.diskHandler?.deleteAllOnDisk(using: cache)
    }
    
    func testDeleteFile() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.insert(["1", "2", "3"], forKey: "Numbers")
        guard let fileURL = cache.diskHandler?.fileURL(for: "Numbers", using: cache) else { return XCTFail("Could not get URL") }
        XCTAssertTrue(Path(url: fileURL)?.exists ?? false)
        
        // Delete
        let didDelete = cache.diskHandler?.deleteFromDisk(with: "Numbers", using: cache) ?? false
        XCTAssertTrue(didDelete)
        XCTAssertFalse(Path(url: fileURL)?.exists ?? true)
        
        // Clean up
        cache.diskHandler?.deleteAllOnDisk(using: cache)
    }
    
    func testDeleteAll() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.insert(["1", "2", "3"], forKey: "Numbers")
        cache.insert(["Hello", "World"], forKey: "Greeting")
        cache.diskHandler?.deleteAllOnDisk(using: cache)
        
        guard let cacheURL = cache.diskHandler?.localCacheURL else { return XCTFail("Could not get cache URL") }
        let path = Path(url: cacheURL)
        XCTAssertFalse(path?.exists ?? true)
    }
    
    func testSizeString() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        cache.insert(["1", "2", "3"], forKey: "Numbers")
        cache.insert(["Hello", "World"], forKey: "Greeting")
        let size = cache.diskHandler?.size
        XCTAssertEqual(size, "8 KB")
        
        // Clean up
        cache.diskHandler?.deleteAllOnDisk(using: cache)
    }
    
    func testLargerSizeString() {
        let cache = Cache<String, [String]>(useLocalDisk: true)
        for _ in 1...500 {
            cache.insert([""], forKey: UUID().uuidString)
        }
        let size = cache.diskHandler?.size
        XCTAssertEqual(size, "13 MB")
        
        // Clean up
        cache.diskHandler?.deleteAllOnDisk(using: cache)
    }
    
    // MARK: - Mock
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
