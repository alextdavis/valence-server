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
        return row
    }

    func artists() -> Siblings<Song, Artist, Pivot<Song, Artist>> {
        return siblings()
    }

    func tags() -> Siblings<Song, Tag, Pivot<Song, Tag>> {
        return siblings()
    }

//    func album() throws -> Album {
//        return try parent()
//    }
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
