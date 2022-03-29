//
//  File.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation

public enum CacheHelper {
    public static let containingFolder = "DHCache"
    public static var fileManager: FileManager = .default
    public static var localCacheFileExtension: String = ".cache"
    public static var localCacheURL: URL? = try? CacheHelper.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(CacheHelper.containingFolder)
    
    @discardableResult public static func deleteAllOnDisk() -> Bool {
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
