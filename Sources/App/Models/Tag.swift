import Vapor
import FluentProvider

final class Tag: Model {
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

    var songs: Siblings<Tag, Song, Pivot<Tag, Song>> {
        return siblings()
    }

    var artists: Siblings<Tag, Artist, Pivot<Tag, Artist>> {
        return siblings()
    }

    var albums: Siblings<Tag, Album, Pivot<Tag, Album>> {
        return siblings()
    }
}

extension Tag: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { tags in
            tags.id()
            tags.string("name")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Tag {
    func makeJSON() -> JSON {
        return JSON.makeFromDict(["id": id, "name": name])
    }
}
