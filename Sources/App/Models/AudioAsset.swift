import Vapor
import FluentProvider
import HTTP
import Foundation
import Crypto

final class AudioAsset: Model {
    static var calculateChecksums: Bool = false

    let storage = Storage()
    var url: String
    var checksum: String?
    var contentType: String

    static func findOrCreate(url: String, contentType: String) throws -> AudioAsset {
        if calculateChecksums {
            if let checksum = fileChecksum(path: url) {
                if let ma = ((try? AudioAsset.makeQuery().filter("checksum", checksum).first()) ?? nil) {
                    return ma
                }
            } else {
                print("FATAL: AudioAsset findOrCreate failure")
                throw SomeError()
            }
        }
        let ma = try AudioAsset(url: url, contentType: contentType)
        try ma.save()
        return ma
    }

    init(url: String, contentType: String) throws {
        self.url = url
        self.contentType = contentType
        if AudioAsset.calculateChecksums {
            if let checksum = fileChecksum(path: url) {
                self.checksum = checksum
            } else {
                print("FATAL: MediaAsset file not found")
                throw SomeError()
            }
        }
    }

    convenience init?(json: JSON?) {
        if let url = json?.object?["url"]?.string {
            if let contentType = json?.object?["content_type"]?.string {
                do {
                    try self.init(url: url, contentType: contentType)
                    return
                } catch {
                    return nil
                }
            }
        }
        return nil
    }

    init(row: Row) throws {
        url = try row.get("url")
        checksum = try row.get("checksum")
        contentType = try row.get("content_type")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("url", url)
        try row.set("checksum", checksum)
        try row.set("content_type", contentType)
        return row
    }
}

extension AudioAsset: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { audioAssets in
            audioAssets.id()
            audioAssets.string("url", length: 512)
            audioAssets.string("checksum", optional: true)
            audioAssets.string("content_type")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
