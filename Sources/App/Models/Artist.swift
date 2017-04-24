import Vapor
import FluentProvider
import HTTP

final class Artist: Model {
    let storage = Storage()
    var name: String

    init(row: Row) throws {
        name = try row.get("name")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        return row
    }

    func albums() throws -> Siblings<Artist, Album, Pivot<Artist, Album>> {
        return siblings()
    }

    func songs() throws -> Siblings<Artist, Song, Pivot<Artist, Song>> {
        return siblings()
    }

//    func tags() throws -> Siblings<Tag> {
//        return try Siblings()
//    }

    func portrait() throws -> MediaAsset? {
        return try children().first()
    }
}

extension Artist: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { artists in
            artists.id()
            artists.string("name")
            artists.foreignId(for: MediaAsset.self, optional: true)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

//Does Fluent support having multiple separate relations with a single other model? For example if I have a MediaAssets table, and I want my Song to have an artwork and audio
