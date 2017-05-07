//
//  Ingester.swift
//  vtunes
//
//  Created by Alex Davis on 4/30/17.
//
//

import Foundation
import Vapor
import Regex

public class Ingester {
    private(set) var ignoredFiletypes: Dictionary<String, Int> = Dictionary()
    private(set) var dupeUrls: [String] = []
    private(set) var dupeChecksums: [String] = []
    private var existingMediaChecksums: [String] = []
    private var existingMediaUrls: [String] = []
    
    public init() {
        
    }
    
    public func recursiveIngest(_ dirPath: String) {
        if dirPath == "Apple Music" || dirPath == "Voice Memos" {
            return
        }
        
        let dirEnumerator = FileManager.default.enumerator(atPath: dirPath)
        while let file = dirEnumerator?.nextObject() {
            let filePath = String(describing: file)
            print("File: \(filePath)")
            var isDirectory = ObjCBool(false)
            FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
            if (isDirectory.boolValue) {
                recursiveIngest(filePath)
            } else if let match = "\\.(pdf|epub|ibooks|m4b|m4v|m4r|m4p)$".r?.findFirst(in: filePath) {
                if let ext = match.group(at: 1) {
                    if ignoredFiletypes[ext] == nil {
                        ignoredFiletypes[ext] = 0
                    } else {
                        ignoredFiletypes[ext]! += 1
                    }
                }
            } else if let match = "\\.(m4a|mp3)$".r?.findFirst(in: filePath) {
                
            }
        }
    }
}
