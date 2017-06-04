import Vapor
import FluentProvider
import HTTP

final class Song: Model {
    let storage = Storage()
    var name: String
    var track: Int
    var disc: Int
    var rating: Int
    var rank: Int
    var time: Int
    var playCount: Int
    var lyrics: String
    var comment: String
    var added: Int
    var modified: Int
    var lastPlayed: Int

    let albumId: Identifier
    let mediaAssetId: Identifier

    var owner: Parent<Song, Album> {
        return parent(id: albumId)
    }

    init(name: String, track: Int, rating: Int, rank: Int, album: Identifier, mediaAsset: Identifier, time: Int, playCount: Int = 0) {
        self.name = name
        self.track = track
        self.rating = rating
        self.rank = rank
        self.albumId = album
        self.mediaAssetId = mediaAsset
        self.time = time
        self.playCount = playCount

        self.disc = 0
        self.lyrics = ""
        self.comment = ""
        self.added = 0
        self.modified = 0
        self.lastPlayed = 0
    }

    init?(json: JSON?, album: Identifier, mediaAsset: Identifier) {
        if let jobj = json?.object {
            guard let name = jobj["name"]?.string,
                  let track = jobj["track"]?.int,
                  let rating = jobj["rating"]?.int,
                  let rank = jobj["rank"]?.int,
                  let time = jobj["time"]?.int else {
                return nil
            }
            self.name = name
            self.track = track
            self.rating = rating
            self.rank = rank
            self.albumId = album
            self.mediaAssetId = mediaAsset
            self.time = time
            self.playCount = jobj["play_count"]?.int ?? 0

            self.disc = jobj["disc"]?.int ?? 0
            self.lyrics = jobj["lyrics"]?.string ?? ""
            self.comment = jobj["comment"]?.string ?? ""
            self.added = jobj["added"]?.int ?? 0
            self.modified = jobj["modified"]?.int ?? 0
            self.lastPlayed = jobj["last_played"]?.int ?? 0
        } else {
            return nil
        }
    }

    init(row: Row) throws {
        name = try row.get("name")
        track = try row.get("track")
        disc = try row.get("disc")
        rating = try row.get("rating")
        rank = try row.get("rank")
        time = try row.get("time")
        playCount = try row.get("playCount")
        lyrics = try row.get("lyrics")
        comment = try row.get("comment")
        added = try row.get("added")
        modified = try row.get("modified")
        lastPlayed = try row.get("lastPlayed")
        albumId = try row.get("album_id")
        mediaAssetId = try row.get("media_asset_id")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("track", track)
        try row.set("disc", disc)
        try row.set("rating", rating)
        try row.set("rank", rank)
        try row.set("time", time)
        try row.set("playCount", playCount)
        try row.set("lyrics", lyrics)
        try row.set("comment", comment)
        try row.set("added", added)
        try row.set("modified", modified)
        try row.set("lastPlayed", lastPlayed)
        try row.set("album_id", albumId)
        try row.set("media_asset_id", mediaAssetId)
        return row
    }

    var artists: Siblings<Song, Artist, Pivot<Song, Artist>> {
        return siblings()
    }

    var tags: Siblings<Song, Tag, Pivot<Song, Tag>> {
        return siblings()
    }

    var album: Album? {
        return try? parent(id: albumId).first()!
    }

    var audioAsset: MediaAsset? {
        return try? children().first()!
    }
}

extension Song: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { songs in
            songs.id()
            songs.string("name")
            songs.int("track")
            songs.int("disc")
            songs.int("rating")
            songs.int("rank")
            songs.int("time")
            songs.int("playCount")
            songs.string("lyrics")
            songs.string("comment")
            songs.int("added")
            songs.int("modified")
            songs.int("lastPlayed")
            songs.foreignId(for: MediaAsset.self) //audio_asset
            songs.foreignId(for: Album.self)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Song: JSONRepresentable {
    func makeJSON() -> JSON {
        return JSON.makeFromDict([
                "id": id,
                "name": name,
                "track": track,
                "disc": disc,
                "rating": rating,
                "rank": rank,
                "time": time,
                "play_count": playCount,
                "lyrics": lyrics,
                "comment": comment,
                "added": added,
                "modified": modified,
                "tags": try? tags.all().map({ $0.name }),
                "last_played": lastPlayed,
                "album_id": albumId,
                "media_asset_id": mediaAssetId,
                "album_name": self.album?.name,
                "album_year": self.album?.year,
                "artists": try? self.artists.all().map({ $0.name })
        ])
    }

    func makeJSON(cols: [String]) -> JSON {
        var dict: [String: Any?] =
                ["id": id,
                 "name": name,
                 "track": track,
                 "rating": rating,
                 "rank": rank,
                 "time": time]
        if cols.contains("tags") {
            dict["tags"] = try? tags.all().map({ $0.name })
        }
        if cols.contains("artists") {
            dict["artists"] = try? artists.all().map({ $0.makeJSON() })
        }
        if cols.contains("album") {
            dict["album"] = album?.makeJSON()
        }
        if cols.contains("year") {
            dict["year"] = album?.year
        }

        return JSON.makeFromDict(dict)
    }
}
