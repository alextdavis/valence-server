import Vapor
import FluentProvider
import HTTP
import Foundation
import CryptoSwift

final class ImageAsset: Model {
    static let none = try! ImageAsset.find(1)!
    //TODO: Do better than this singleton thing

    let storage = Storage()
    var path: String
    var checksum: String
    var contentType: String

    static func findOrCreate(url: String, contentType: String) throws -> ImageAsset {
        if let checksum = FileManager.default.contents(atPath: url)?.md5().base64EncodedString() {
            if let ma = ((try? ImageAsset.makeQuery().filter("checksum", checksum).first()) ?? nil) {
                return ma
            } else {
                let ma = try ImageAsset(path: url, contentType: contentType)
                try ma.save()
                return ma
            }
        } else {
            print("FATAL: ImageAsset findOrCreate failure")
            throw SomeError()
        }
    }

    init(path: String, contentType: String) throws {
        self.path = path
        self.contentType = contentType
        if let checksum = FileManager.default.contents(atPath: path)?.md5() {
            self.checksum = checksum.base64EncodedString()
        } else {
            print("FATAL: ImageAsset file not found")
            throw SomeError()
        }

    }

    @available(*, deprecated)
    convenience init?(json: JSON?) {
        if let path = json?.object?["url"]?.string {
            if let contentType = json?.object?["content_type"]?.string {
                do {
                    try self.init(path: path, contentType: contentType)
                    return
                } catch {
                    return nil
                }
            }
        }
        return nil
    }

    init(row: Row) throws {
        path = try row.get("path")
        checksum = try row.get("checksum")
        contentType = try row.get("content_type")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("path", path)
        try row.set("checksum", checksum)
        try row.set("content_type", contentType)
        return row
    }
}

extension ImageAsset: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { mediaAssets in
            mediaAssets.id()
            mediaAssets.string("path")
            mediaAssets.string("checksum")
            mediaAssets.string("content_type")
        }
        let VALENCE_DIR = "/Users/alex/Music/Valence" // somehow make this global or something
        try ImageAsset(path: "\(VALENCE_DIR)/Thumbnails/none.jpg", contentType: "image/png").save()
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}