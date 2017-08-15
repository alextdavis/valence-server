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

    init(_ source: String) throws {
        self.source = source
        print(source)
        print(try Search.parse(source))
    }

    func getJSON(orderBy: String? = "album_sort_artist, year, album_name, disc, track") throws -> String? {
        let isOrdered = orderBy != nil
        guard !isOrdered || orderBy! =~ "\\A[\\w .,]*\\z".r else {
            throw SearchError.sanitationError
        }
        try issueQuery()

        let orderStr = isOrdered ? ("ORDER BY " + orderBy!) : ""
        let sqlQuery = "SELECT array_to_json(array_agg(row_to_json(a)))FROM" +
                "(SELECT id, name, rank, track, time, rating, year," +
                "        (SELECT array_to_json(array_agg(row_to_json(b)))" +
                "         FROM (SELECT a.id, a.name " +
                "               FROM artists AS a, songs AS s, artist_song AS ass" +
                "               WHERE a.id = ass.artist_id AND s.id = ass.song_id AND s.id = songs.id" +
                "              ) b)                         artists," +
                "        (SELECT array_to_json(array_agg(row_to_json(c)))" +
                "         FROM (SELECT t.id, t.name " +
                "               FROM tags AS t, songs AS s, song_tag AS ts" +
                "               WHERE t.id = ts.tag_id AND s.id = ts.song_id AND s.id = songs.id" +
                "              ) c)                         tags," +
                "        album_id," +
                "        (SELECT albums.name" +
                "         FROM albums" +
                "         WHERE albums.id = songs.album_id) album_name," +
                "        (SELECT albums.sort_artist" +
                "         FROM albums" +
                "         WHERE albums.id = songs.album_id) album_sort_artist" +
                "      FROM songs" +
                "      WHERE songs.id IN (\(resultCSV())) " +
                orderStr +
                "     ) a"
        return try Song.database!.raw(sqlQuery)[0]?["array_to_json"]?.string
    }

    func getIDs(orderBy: String? = nil) throws -> [Int] {
        guard orderBy == nil || orderBy! =~ "\\A[\\w .,]*\\z".r else {
            throw SearchError.sanitationError
        }
        try issueQuery()
        if orderBy == nil {
            return results!
        } else {
            return try Song.database!.raw("SELECT songs.id " +
                    "FROM songs " +
                    "INNER JOIN albums ON songs.album_id = albums.id " +
                    "WHERE songs.id IN (\(resultCSV())) " +
                    "ORDER BY \(orderBy!)").array?.map({ $0["id"]?.int }).flatMap({ $0 }) ?? results!
        }
    }

    func getSongs() throws -> [Song] {
        try issueQuery()
        return try Song.makeQuery().filter(raw: "IN (\(resultCSV()))").all()
    }

    func issueQuery() throws {
        if results == nil {
            results = try Song.database!.raw(try Search.parse(source)).array?.map({ $0["id"]?.int }).flatMap({ $0 })
        }
        guard results != nil  else {
            throw SearchError.queryResponseError
        }
    }

    init(row: Row) throws {
        source = try row.get("source")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("source", source)
        return row
    }


    private func resultCSV() -> String {
        let resultStr = String(describing: results!)
        return resultStr[
                resultStr.index(resultStr.startIndex, offsetBy: 1)..<resultStr.index(resultStr.endIndex, offsetBy: -1)]
    }

    private static func parse(_ str: String) throws -> String {
        var sqlStr = "SELECT songs.id " +
                "FROM songs " +
                "LEFT JOIN song_tag on songs.id = song_tag.song_id " +
                "LEFT JOIN artist_song ON songs.id = artist_song.id " +
                "WHERE "
        if str == "all" {
            return sqlStr + "1=1"
        }
        let rx = "[@#$%]\\d+|,|and|or|not|:(\\w+) (true|false|([<>=!]=? )?(\\d+)|([=~{] )?(\"[^\"]+\"))|\\(|\\)".r!
        for token in rx.findAll(in: str) {
            print(token.matched)
            switch token.matched {
            case "@\\d+".r:
                sqlStr += " artist_song.artist_id = \(removeFirstChar(of: token.matched)) "
            case "#\\d+".r:
                sqlStr += " song_tag.tag_id = \(removeFirstChar(of: token.matched)) "
            case "$\\d+".r:
                sqlStr += " songs.id = \(removeFirstChar(of: token.matched)) "
            case "%\\d+".r:
                sqlStr += " songs.album_id = \(removeFirstChar(of: token.matched)) "
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
            case ":(track|disc|rating|rank|time|play_count|year|added|modified|last_played) ([<>=!]=? )?\\d+".r:
                let op = "[<>=]|!=|<=|>=".r?.findFirst(in: token.matched)?.matched ?? "="
                sqlStr += " songs.\(token.group(at: 1)!) \(op) \(token.group(at: 4)!) "
            case ":(name|lyrics|comment) =? \"[^\"]+\"".r:
                sqlStr += " songs.\(token.group(at: 1)!) = \(token.group(at: 6)!)"
            default:
                print("ERR: Invalid clause `\(token.matched)`}} ")
                throw SearchError.parseError
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

enum SearchError: Swift.Error {
    case parseError
    case sanitationError
    case queryResponseError
}
