import Vapor
import FluentProvider
import HTTP

final class Album: Model {
    let storage = Storage()
    var name: String
    var year: Int

    static func findOrCreate(name: String) throws -> Album? {
        do {
            if let album = try Album.makeQuery().filter("name", name).first() {
                return album
            }
        }

        let album = Album(name: name)
        try album.save()
        return album

    }

    static func findOrCreate(json: JSON?) throws -> Album? {
        var album: Album?
        if let name = json?.object?["name"]?.string {
            try album = self.findOrCreate(name: name)
        }
        if let year = json?.object?["year"]?.int {
            album?.year = year
            try album?.save()
        }
        return album
    }

    init(name: String, year: Int = 0) {
        self.name = name
        self.year = year
    }

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

    var artists: Siblings<Album, Artist, Pivot<Album, Artist>> {
        return siblings()
    }

    var songs: Children<Album, Song> {
        return children()
    }

    //    var tags: Siblings<Tag> {
    //        return siblings()
    //    }

    var artwork: MediaAsset? {
        return (try? children().first()) ?? nil
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

extension Album: JSONRepresentable {

    public enum Selection {
        case nid, basic, all
    }

    func makeJSON() -> JSON {
        return self.makeJSON(.all)
    }

    func makeJSON(_ selection: Selection) -> JSON {
        var dict:[String: Any?] = ["id": id, "name": name]
        if (selection == .basic || selection == .all) {

            dict["year"] = year
            dict["artwork_url"] = artwork?.url
        }
        if (selection == .all) {
            dict["artists"] = try? self.artists.all().map({ $0.makeJSON() })
            dict["artists_ids"] = try? self.artists.all().map({ $0.id })

        }
        return JSON.makeFromDict(dict)
    }
}
