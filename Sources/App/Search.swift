//
// Created by alex on 7/25/17.
//

import Foundation
import Vapor
import FluentProvider
import Regex

final class Search: Model {
    let storage = Storage()
    let source: String
    var results: [Int]?

    init(_ source: String) {
        self.source = source
        print(Search.parse(source))
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
                "      WHERE " +
                "      ORDER BY album_sort_artist, year, album_name, disc, track" +
                "     ) a")
    }

    func issueQuery() {
        results = []
    }

    func getIDs() -> [Int] {
        if results == nil {
            self.issueQuery()
        }
        return results!
    }

    init(row: Row) throws {
        source = try row.get("source")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("source", source)
        return row
    }

    private static func parse(_ str: String) -> String {
        var sqlStr = ""
        let rx = "[@#$%]\\d+|,|and|or|not|:(\\w+) (true|false|([<>=!]=? )?(\\d+)|([=~{] )?(\"[^\"]+\"))|\\(|\\)".r!
        for token in rx.findAll(in: str) {
            print(token.matched)
            switch token.matched {
            case "@\\d+".r:
                sqlStr += " artist = \(removeFirstChar(of: token.matched)) "
            case "#\\d+".r:
                sqlStr += " tag = \(removeFirstChar(of: token.matched)) "
            case "$\\d+".r:
                sqlStr += " song.id = \(removeFirstChar(of: token.matched)) "
            case "%\\d+".r:
                sqlStr += " song.album_id = \(removeFirstChar(of: token.matched)) "
            case "and":
                sqlStr += " and "
            case "or", ",":
                sqlStr += " or "
            case "not":
                sqlStr += " not "
            case "(":
                sqlStr += "("
            case ")":
                sqlStr += ")"
            case ":(track|disc|rating|rank|time|play_count|year|added|modified|last_played) (= )?\\d+".r:
                sqlStr += " song.\(token.group(at: 1)!) = \(token.group(at: 4)!) "
            case ":(name|lyrics|comment) =? \"[^\"]+\"".r:
                sqlStr += " song.\(token.group(at: 1)!) = \(token.group(at: 6)!)"
            default:
                sqlStr += " {{ERR: Invalid clause `\(token.matched)`}} "
            }
        }
        return sqlStr
    }

    private static func removeFirstChar(of str: String) -> String {
        var mstr = String(str)!
        mstr.remove(at: mstr.startIndex)
        return mstr
    }
}
