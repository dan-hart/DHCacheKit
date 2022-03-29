//
//  NoDiskCacheTests.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

@testable import DHCacheKit
import XCTest
import FileKit

class NoDiskCacheTests: XCTestCase {
    func testInit() {
        let cache = Cache<String, [String]>(useLocalDisk: false)
        XCTAssertNotNil(cache)
        XCTAssertFalse(cache.useLocalDisk)
    }
    
    func testInsert() {
        let cache = Cache<String, [String]>(useLocalDisk: false)
        cache.insert(["1", "2"], forKey: "Count")
        XCTAssertNil(cache.diskHandler?.fileURL(for: "Count", using: cache))
        cache.insert(["1", "2", "3"], forKey: "Count")
        let entry = cache.entry(forKey: "Count")
        XCTAssertEqual(entry?.value, ["1", "2", "3"])
    }
    
    func testDelete() {
        let cache = Cache<String, [String]>(useLocalDisk: false)
        cache.insert(["1", "2"], forKey: "Count")
        let entry = cache.entry(forKey: "Count")
        XCTAssertEqual(entry?.value, ["1", "2"])
        cache.removeValue(forKey: "Count")
        XCTAssertNil(cache.entry(forKey: "Count"))
    }
    
    func testEntryLimit() {
        let cache = Cache<String, [String]>(maximumEntryCount: 2, useLocalDisk: false)
        cache.insert(["1"], forKey: "One")
        cache.insert(["2"], forKey: "Two")
        cache.insert(["3"], forKey: "Three")
        
        // First in, first out (FIFO)
        XCTAssertNil(cache.entry(forKey: "One"))
        XCTAssertNotNil(cache.entry(forKey: "Two"))
        XCTAssertNotNil(cache.entry(forKey: "Three"))
    }
    
    func testTimeout() {
        let cache = Cache<String, [String]>(entryLifetime: 0.1, useLocalDisk: false)
        cache.insert(["Hi"], forKey: "Test")
        XCTAssertNotNil(cache.entry(forKey: "Test"))
        let expectToWait = expectation(description: "Wait for Timeout")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
            expectToWait.fulfill()
        }
        wait(for: [expectToWait], timeout: 0.3)
        XCTAssertNil(cache.entry(forKey: "Test"))
    }
}
