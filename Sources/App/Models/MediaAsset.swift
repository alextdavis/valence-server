import Vapor
import FluentProvider
import HTTP
import Foundation
import CryptoSwift

final class MediaAsset: Model {
    static let none = try! MediaAsset.find(1)! //TODO: Do better than this singleton thing

    let storage = Storage()
    var url: String
    var checksum: String
    var contentType: String

    static func findOrCreate(url: String, contentType: String) throws -> MediaAsset {
        if let checksum = FileManager.default.contents(atPath: url)?.md5().base64EncodedString() {
            if let ma = ((try? MediaAsset.makeQuery().filter("checksum", checksum).first()) ?? nil) {
                return ma
            } else {
                let ma = try MediaAsset(url: url, contentType: contentType)
                try ma.save()
                return ma
            }
        } else {
            print("FATAL: MediaAsset findOrCreate failure")
            throw SomeError()
        }
    }

    init(url: String, contentType: String) throws {
//        print("init MediaAsset with URL: \(url)")

        self.url = url
        self.contentType = contentType
        if contentType.contains("audio") {
            self.checksum = ""
        } else {
            if let checksum = FileManager.default.contents(atPath: url)?.md5() {
                self.checksum = checksum.base64EncodedString()
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
        contentType = try row.get("contentType")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("url", url)
        try row.set("checksum", checksum)
        try row.set("contentType", contentType)
        return row
    }
}

extension MediaAsset: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { mediaAssets in
            mediaAssets.id()
            mediaAssets.string("url")
            mediaAssets.string("checksum")
            mediaAssets.string("contentType")
        }
        let VALENCE_DIR = "/Users/alex/Music/Valence"
        try MediaAsset(url: "\(VALENCE_DIR)/Thumbnails/none.jpg", contentType: "image/png").save()
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
