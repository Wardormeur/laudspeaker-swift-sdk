//
//  LaudspeakerFileBackedQueue.swift
//  Laudspeaker
//
//

import Foundation

class LaudspeakerFileBackedQueue {
    let queue: URL
    //@ReadWriteLock
    private var items = [String]()

    var depth: Int {
        items.count
    }

    init(queue: URL, oldQueue: URL) {
        self.queue = queue
        setup()
    }
    
    
    
    private func setup() {
        do {
            try FileManager.default.createDirectory(atPath: queue.path, withIntermediateDirectories: true)
        } catch {
            print("Error trying to create caching folder \(error)")
        }

        do {
            items = try FileManager.default.contentsOfDirectory(atPath: queue.path)
            items.sort { Double($0)! < Double($1)! }
        } catch {
            print("Failed to load files for queue \(error)")
            // failed to read directory – bad permissions, perhaps?
        }
    }
    

    func peek(_ count: Int) -> [Data] {
        loadFiles(count)
    }

    func delete(index: Int) {
        if items.isEmpty { return }
        let removed = items.remove(at: index)

        deleteSafely(queue.appendingPathComponent(removed))
    }

    func pop(_ count: Int) {
        deleteFiles(count)
    }

    func add(_ contents: Data) {
        print("adding to file queu");
        do {
            let filename = "\(Date().timeIntervalSince1970)"
            try contents.write(to: queue.appendingPathComponent(filename))
            items.append(filename)
        } catch {
            print("Could not write file \(error)")
        }
    }

    func clear() {
        deleteSafely(queue)
        //setup(oldQueue: nil)
    }

    private func loadFiles(_ count: Int) -> [Data] {
        var results = [Data]()

        for item in items {
            let itemURL = queue.appendingPathComponent(item)
            do {
                if !FileManager.default.fileExists(atPath: itemURL.path) {
                    //print("File \(itemURL) does not exist")
                    continue
                }
                let contents = try Data(contentsOf: itemURL)

                results.append(contents)
            } catch {
                //print("File \(itemURL) is corrupted \(error)")

                deleteSafely(itemURL)
            }

            if results.count == count {
                return results
            }
        }

        return results
    }

    private func deleteFiles(_ count: Int) {
        for _ in 0 ..< count {
            if items.isEmpty { return }
            let removed = items.remove(at: 0) // We always remove from the top of the queue

            deleteSafely(queue.appendingPathComponent(removed))
        }
    }
}
