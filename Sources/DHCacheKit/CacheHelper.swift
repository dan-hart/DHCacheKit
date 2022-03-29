//
//  CacheHelper.swift
//  
//
//  Created by Dan Hart on 3/29/22.
//

import Foundation

public enum CacheHelper {
    @discardableResult
    static func clearAllCaches(using fileManager: FileManager = .default) -> Bool {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let folderURL = folderURLs[0]

        var didSucceed = true
        do {
            let filePaths = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            for filePath in filePaths {
                try fileManager.removeItem(at: filePath)
            }
        } catch {
            didSucceed = false
        }

        return didSucceed
    }
}
