import Vapor
import FluentProvider
import HTTP

final class Album: Model {
    let storage = Storage()
    var name: String
    var year: Int

    init(row: Row) throws {
        name = try row.get("name")
        year = try row.get("year")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("year", year)
        return row
    }

    func artists() throws -> Siblings<Album, Artist, Pivot<Album, Artist>> {
        return siblings()
    }

    func songs() throws -> Siblings<Album, Song, Pivot<Album, Song>> {
        return siblings()
    }

//    func tags() throws -> Siblings<Tag> {
//        return try siblings()
//    }

    func artwork() throws -> MediaAsset? {
        return try children().first()
    }
}

extension Album: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { albums in
            albums.id()
            albums.string("name")
            albums.int("year")
            albums.foreignId(for: MediaAsset.self, optional: true)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
