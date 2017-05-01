import Vapor
import FluentProvider
import HTTP

final class MediaAsset: Model {
    let storage = Storage()
    var url: String
    var checksum: String
    var contentType: String

    init(url: String, contentType: String) {
        self.url = url
        self.contentType = contentType
        self.checksum = ""
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
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
