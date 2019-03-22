//
//  DuplicateHandler.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 16.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation
import DotphotonCompressBackend

class DuplicateHandler {
    
    typealias DuplicateMap = [String: [Node<CompressionItem>]]
    
    var queue: IsolationLinkedList<CompressionItem>
    
    enum Resolution {
        case skipping
        case renaming
        case overwriting
    }
    
    init(queue: IsolationLinkedList<CompressionItem>) {
        self.queue = queue
    }
    
    func checkForInputDuplicates() -> DuplicateMap {
        // Since directory structure is not preserved, inputs with the same file name
        // (modulo extension) will result in the same output file name, and would overwrite each other.
        
        var duplicateMap = DuplicateMap()
        for i in 0 ..< queue.count {
            if let node = queue.nodeAt(index: i) {
                let inFileUrl = node.value.inURL
                let inFileName = inFileUrl.deletingPathExtension().lastPathComponent
                if duplicateMap.keys.contains(inFileName) {
                    duplicateMap[inFileName]!.append(node)
                } else {
                    // The first occurence is not stored.
                    duplicateMap[inFileName] = []
                }
            }
        }
        return duplicateMap
    }
    
    func resolveInputDuplicate(node: Node<CompressionItem>, in map: inout DuplicateMap, by method: Resolution, applyToAll: Bool) {
        let inFileName = node.value.inURL.deletingPathExtension().lastPathComponent
        
        switch method {
        case .skipping:
            // Remove from queue and map
            let _ = queue.remove(node: node)
            if let index = map[inFileName]?.index(of: node) {
                map[inFileName]!.remove(at: index)
            }
            
        case .renaming:
            // Remove from map
            if let index = map[inFileName]?.index(of: node) {
                map[inFileName]!.remove(at: index)
            }
            
            // Generate unique file name and re-add
            var i = 1
            while(map.keys.contains(inFileName + "_\(i)")) { i += 1 }
            node.value.outputFileName = inFileName + "_\(i)"
            map[node.value.outputFileName!] = []
            
        case .overwriting:
            preconditionFailure("Overwriting is not a valid choice for input duplicates.")
        }
        
        if applyToAll {
            let nodes = map.values.joined()
            nodes.forEach { resolveInputDuplicate(node: $0, in: &map, by: method, applyToAll: false)}
        }
    }
    
    func checkForOutputConflicts(for directoryUrl: URL) -> [Node<CompressionItem>] {
        // We assume that the input duplicates have been checked, and hence queue contains
        // items that were not skipped and may have been renamed.
        var conflicts = [Node<CompressionItem>]()
        
        for i in 0 ..< queue.count {
            if let node = queue.nodeAt(index: i) {
                let inFileName = node.value.nonNilOutputFileName
                let outFileUrl = directoryUrl.appendingPathComponent(inFileName).appendingPathExtension("p.dng")
                if FileManager.default.fileExists(atPath: outFileUrl.path) {
                    conflicts.append(node)
                }
            }
        }
        return conflicts
    }
    
    func resolveOutputConflicts(node: Node<CompressionItem>, in list: inout [Node<CompressionItem>], for directoryUrl: URL,
                                by method: Resolution, applyToAll: Bool) {
        
        switch method {
        case .skipping:
            // Remove from queue and map
            let _ = queue.remove(node: node)
            if let index = list.index(of: node) {
                list.remove(at: index)
            }
            
        case .renaming:
            // Renaming is tricky, because other files in the queue may have been "renamed" to resolve input
            // conflicts. When choosing an output name, this needs to be taken into account.
            
            // Remove from list
            if let index = list.index(of: node) {
                list.remove(at: index)
            }
            
            // Generate unique file
            let inFileName = node.value.nonNilOutputFileName
            var i = 1
            var outFileName = inFileName + "_\(i)"
            let otherFiles: [String] = ( 0 ..< queue.count).map {queue.nodeAt(index: $0)!.value.nonNilOutputFileName }
            while(otherFiles.contains(outFileName)
                || FileManager.default.fileExists(atPath: directoryUrl.appendingPathComponent(outFileName).appendingPathExtension("p.dng").path)) {
                i += 1
                outFileName = inFileName + "_\(i)"
            }
            node.value.outputFileName = outFileName
            // print("Final output file name: ", node.value.outputFileName)
            
        case .overwriting:
            // We just need to remove the item from the list of conflicts. Overwriting happens by default in the CompressionWorker.
            if let index = list.index(of: node) {
                list.remove(at: index)
            }
        }
        
        if applyToAll {
            list.forEach { resolveOutputConflicts(node: $0, in: &list, for: directoryUrl, by: method, applyToAll: false)}
        }
    }
}
