//
// Created by alex on 7/25/17.
//

import Foundation
import Vapor
import FluentProvider

final class Search: Model {
    let storage = Storage()
    let source: String?
    let clause: SearchClause

    init(_ clause: SearchClause) {
        source = nil
        self.clause = clause
    }

    func getJSON() throws -> Node {
        return try Song.database!.raw("SELECT array_to_json(array_agg(row_to_json(a)))FROM" +
                "(SELECT id, name, rank, track, time, rating, year," +
                "        (SELECT array_to_json(array_agg(row_to_json(b)))" +
                "         FROM (SELECT a.id, a.name " +
                "               FROM artists AS a, songs AS s, artist_song AS ass" +
                "               WHERE a.id = ass.artist_id AND s.id = ass.song_id AND s.id = songs.id" +
                "              ) b)                         artists," +
                "        album_id," +
                "        (SELECT albums.name" +
                "         FROM albums" +
                "         WHERE albums.id = songs.album_id) album_name," +
                "        (SELECT albums.sort_artist" +
                "         FROM albums" +
                "         WHERE albums.id = songs.album_id) album_sort_artist" +
                "      FROM songs" +
                "      WHERE \(clause.makeSQL())" +
                "      ORDER BY album_sort_artist, year, album_name, disc, track" +
                "     ) a")
    }

//    func getIDs() -> [Int] {
//
//    }

//    init(parse str: String) {
//        self.query = str
//        //do stuff
//    }

    init(row: Row) throws {
        source = try row.get("source")
        clause = NullClause()
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("source", source)
        return row
    }

//    private static func parse(_ str: String) -> SearchClause {
//        switch str {
//            case "^\\s*(#|\\$|%|@)\\d+\\s*$".r:
//                let match = "^\\s*(#|\\$|%|@)(\\d+)\\s*$".r!.findFirst(in:str)!
//                switch match.group(at: 1)! {
//                    case "#":
//                        return AlbumClause(match.group(at:2))
//                }
//        }
//    }

}


protocol SearchClause {
    func makeSQL() -> String
}

class NullClause: SearchClause {
    func makeSQL() -> String {
        return "NULL"
    }
}

struct AndClause: SearchClause {
    let lhs: SearchClause
    let rhs: SearchClause

    init(_ lhs: SearchClause, _ rhs: SearchClause) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func makeSQL() -> String {
        return "(\(lhs.makeSQL()) AND \(rhs.makeSQL()))"
    }
}

struct OrClause: SearchClause {
    let lhs: SearchClause
    let rhs: SearchClause

    init(_ lhs: SearchClause, _ rhs: SearchClause) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func makeSQL() -> String {
        return "(\(lhs.makeSQL()) OR \(rhs.makeSQL()))"
    }
}

struct NotClause: SearchClause {
    let inner: SearchClause

    init(_ inner: SearchClause) {
        self.inner = inner
    }

    func makeSQL() -> String {
        return "(NOT \(inner.makeSQL()))"
    }
}

struct AlbumClause: SearchClause {
    let id: Int

    init(_ id: Int) {
        self.id = id
    }

    func makeSQL() -> String {
        return "songs.album_id = \(id)"
    }
}

struct ArtistClause: SearchClause {
    let id: Int

    init(_ id: Int) {
        self.id = id
    }

    func makeSQL() -> String {
        return ""
    }
}

struct SongClause: SearchClause {
    let id: Int

    init(_ id: Int) {
        self.id = id
    }

    func makeSQL() -> String {
        return "songs.id = \(id)"
    }
}
