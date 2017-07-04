import Vapor
import FluentProvider
import HTTP

final class Artist: Model {
    let storage = Storage()
    var name: String

    static func findOrCreate(name: String) throws -> Artist {
        if let artist = try Artist.makeQuery().filter("name", name).first() {
            return artist
        } else {
            let artist = Artist(name: name)
            try artist.save()
            return artist
        }
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(row: Row) throws {
        name = try row.get("name")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        return row
    }

    var albums: Siblings<Artist, Album, Pivot<Artist, Album>> {
        return siblings()
    }

    var songs: Siblings<Artist, Song, Pivot<Artist, Song>> {
        return siblings()
    }

//    var tags: Siblings<Tag> {
//        return siblings()
//    }

    var portrait: ImageAsset? {
        return (try? children().first()) ?? nil
    }
}

extension Artist: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { artists in
            artists.id()
            artists.string("name")
            artists.foreignId(for: ImageAsset.self, optional: true)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Artist: JSONRepresentable {
    func makeJSON() -> JSON {
        return JSON.makeFromDict(["id": id, "name": name])
    }
}
