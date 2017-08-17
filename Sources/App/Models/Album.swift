import Vapor
import FluentProvider
import HTTP

final class Album: Model {
    let storage = Storage()
    var name: String
    var year: Int
    var artworkAssetId: Identifier?
    var sortArtist: String

    var singlesAlbumArtist: Identifier?
    public var isSinglesAlbum: Bool {
        return singlesAlbumArtist != nil
    }

    static func findOrCreate(name: String,
                             sortArtist: String,
                             year: Int = 0,
                             artworkAssetId: Identifier? = nil) throws -> Album? {
        do {
            if let album = try Album.makeQuery().filter("name", name).first() {
                return album
            }
        }

        let album = Album(name: name, sortArtist: sortArtist, year: year, artworkAssetId: artworkAssetId)
        try album.save()
        return album

    }

    static func findOrCreate(singlesFor artist: Artist?) throws -> Album? {
        if artist == nil {
            return nil
        }
        if let album = ((try? self.makeQuery().filter("singles_album_artist" == artist!.id).first()) ?? nil) {
            return album
        } else {
            let album = Album(singlesArtist: artist!)
            try album.save()
            try album.artists.add(artist!)
            try album.save()
            return album
        }
    }

    init(name: String, sortArtist: String, year: Int = 0, artworkAssetId: Identifier? = nil) {
        self.name = name
        self.year = year
        self.artworkAssetId = artworkAssetId
        self.sortArtist = sortArtist
    }

    convenience init(singlesArtist artist: Artist) {
        self.init(name: "\(artist.name) - Singles", sortArtist: artist.name)
        self.singlesAlbumArtist = artist.id!
    }

    init(row: Row) throws {
        name = try row.get("name")
        year = try row.get("year")
        artworkAssetId = try row.get("image_asset_id")
        sortArtist = try row.get("sort_artist")
        singlesAlbumArtist = try row.get("singles_album_artist")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("year", year)
        try row.set("image_asset_id", artworkAssetId)
        try row.set("sort_artist", sortArtist)
        try row.set("singles_album_artist", singlesAlbumArtist)
        return row
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
}

extension Album: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { albums in
            albums.id()
            albums.string("name")
            albums.int("year")
            albums.string("sort_artist")
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
