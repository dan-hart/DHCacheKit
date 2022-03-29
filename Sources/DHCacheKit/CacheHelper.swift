//
//  File.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation

public enum CacheHelper {
    static let containingFolder = "DHCache"
    static var fileManager: FileManager = .default
    static var localCacheFileExtension: String = ".cache"
    static var localCacheURL: URL? = try? CacheHelper.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(CacheHelper.containingFolder)
    
    @discardableResult static func deleteAllOnDisk() -> Bool {
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
