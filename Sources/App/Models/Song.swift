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
    var year: Int

    var added: Int
    var modified: Int
    var lastPlayed: Int

    var albumId: Identifier
    var audioAssetId: Identifier
    var imageAssetId: Identifier?

    var owner: Parent<Song, Album> {
        return parent(id: albumId)
    }

    init(name: String, track: Int, rating: Int, rank: Int, album: Identifier,
         audioAssetId: Identifier, time: Int, playCount: Int = 0,
         artworkAssetId: Identifier? = nil) {
        self.name = name
        self.track = track
        self.rating = rating
        self.rank = rank
        self.albumId = album
        self.audioAssetId = audioAssetId
        self.imageAssetId = artworkAssetId
        self.time = time
        self.playCount = playCount

        self.disc = 0
        self.lyrics = ""
        self.comment = ""
        self.year = 0

        self.added = 0
        self.modified = 0
        self.lastPlayed = 0
    }

    @available(*, deprecated)
    init?(json: JSON?, album: Identifier, audioAssetId: Identifier,
          artworkAssetId: Identifier? = nil) {
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
            self.audioAssetId = audioAssetId
            self.imageAssetId = artworkAssetId
            self.time = time
            self.playCount = jobj["play_count"]?.int ?? 0

            self.disc = jobj["disc"]?.int ?? 0
            self.lyrics = jobj["lyrics"]?.string ?? ""
            self.comment = jobj["comment"]?.string ?? ""
            self.year = jobj["year"]?.int ?? 0

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
        year = try row.get("year")
        added = try row.get("added")
        modified = try row.get("modified")
        lastPlayed = try row.get("lastPlayed")
        albumId = try row.get("album_id")
        audioAssetId = try row.get("audio_asset_id")
        imageAssetId = try row.get("image_asset_id")
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
        try row.set("year", year)
        try row.set("added", added)
        try row.set("modified", modified)
        try row.set("lastPlayed", lastPlayed)
        try row.set("album_id", albumId)
        try row.set("audio_asset_id", audioAssetId)
        try row.set("image_asset_id", imageAssetId)
        return row
    }

    var artists: Siblings<Song, Artist, Pivot<Song, Artist>> {
        return siblings()
    }

    var artist_str: String {
        return (try? artists.all().map({ $0.name }).joined(separator: ", ")) ?? ""
    }

    var tags: Siblings<Song, Tag, Pivot<Song, Tag>> {
        return siblings()
    }

    var album: Album? {
        get {
            return (try? parent(id: albumId).first()) ?? nil
        }
        set {
            if let id = newValue?.id {
                self.albumId = id
            }
        }
    }

    var audioAsset: AudioAsset? {
        return (try? AudioAsset.find(self.audioAssetId)) ?? nil
    }

    var artworkAsset: ImageAsset {
        if self.imageAssetId != nil, let ma = (try? ImageAsset.find(self.imageAssetId)) ?? nil {
            return ma
        } else {
            return album?.artworkAsset ?? ImageAsset.none
        }
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
            songs.int("year")
            songs.int("added")
            songs.int("modified")
            songs.int("lastPlayed")
            songs.foreignId(for: AudioAsset.self, foreignIdKey: "audio_asset_id")
            songs.foreignId(for: ImageAsset.self, optional: true, foreignIdKey: "image_asset_id")
            songs.foreignId(for: Album.self)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Song: JSONRepresentable {
    public enum Selection: Int {
        case nid = 1, qlist, all
    }

    func makeJSON(_ sel: Selection) -> JSON {
        if sel == .all {
            return self.makeJSON()
        }
        var dict: [String: Any?] = ["id": id, "name": name]
        if (sel.rawValue > 1) {
            dict["artists_names"] = try? self.artists.all().map({ $0.name })

        }
        return JSON.makeFromDict(dict)
    }

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
            "year": year,
            "added": added,
            "modified": modified,
            "tags": try? tags.all().map({ $0.name }),
            "last_played": lastPlayed,
            "album_id": albumId,
            "audio_asset_id": audioAssetId,
            "image_asset_id": imageAssetId,
            "album_name": self.album?.name,
            "album_year": self.album?.year,
            "artists": try? self.artists.all().map({ $0.name }).joined(separator: ", "),
            "artists_names": try? self.artists.all().map({ $0.name }),
            "artists_ids": try? self.artists.all().map({ $0.id }),
        ])
    }

    func makeJSON(cols: [String]) -> JSON { //TODO: Switch to enum system
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
            dict["year"] = year
        }

        return JSON.makeFromDict(dict)
    }
}

extension Song {
    static func songs(ids: [Int]) throws -> [Song] {
        var songs: [Song] = Array()
        for id in ids {
            if let song = try Song.find(id) {
                songs.append(song)
            }
        }
        return songs
    }

    static func songs(ids queue: Queue<Int>) throws -> [Song] {
        return try songs(ids: queue.makeArray())
    }
}
