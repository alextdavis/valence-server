import Vapor
import FluentProvider
import HTTP

class Album: Model {
    let storage = Storage()
    var name: String
    var artworkAssetId: Identifier?

    static func findOrCreate(name: String, artworkAssetId: Identifier? = nil) throws -> Album? {
        do {
            if let album = try Album.makeQuery().filter("name", name).first() {
                return album
            }
        }

        let album = Album(name: name, artworkAssetId: artworkAssetId)
        try album.save()
        return album

    }

    init(name: String, artworkAssetId: Identifier? = nil) {
        self.name = name
        self.artworkAssetId = artworkAssetId
    }

    required init(row: Row) throws {
        name = try row.get("name")
        artworkAssetId = try row.get("image_asset_id")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("image_asset_id", artworkAssetId)
        return row
    }

    var year: Int {
        return ((try? songs.makeQuery().sort("year", .descending).first()?.year) ?? nil) ?? 0
    }

    var artists: Siblings<Album, Artist, Pivot<Album, Artist>> {
        return siblings()
    }

    var songs: Children<Album, Song> {
        return children()
    }

    var tags: Siblings<Album, Tag, Pivot<Album, Tag>> {
        return siblings()
    }

    var artworkAsset: ImageAsset {
        return ((try? ImageAsset.find(artworkAssetId)) ?? nil) ?? ImageAsset.none
    }

    public static func make(for parameter: String) throws -> Self { //Shouldn't need to be here
        let id = Identifier(parameter)
        guard let found = try find(id) else {
            throw Abort(.notFound, reason: "No \(Album.self) with that identifier was found.")
        }
        return found
    }
}

extension Album: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { albums in
            albums.id()
            albums.string("name")
            albums.foreignId(for: Artist.self, optional: true, foreignIdKey: "singles_album_artist")
            albums.foreignId(for: ImageAsset.self, optional: true)
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
        var dict: [String: Any?] = ["id": id, "name": name]
        if (selection == .basic || selection == .all) {
            dict["year"] = year
        }
        if (selection == .all) {
            dict["artists"] = try? self.artists.all().map({ $0.makeJSON() })
            dict["artists_ids"] = try? self.artists.all().map({ $0.id })
        }
        return JSON.makeFromDict(dict)
    }
}
