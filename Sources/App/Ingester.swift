//
//  Ingester.swift
//  vtunes
//
//  Created by Alex Davis on 4/30/17.
//
//

import Foundation
import Vapor
import Regex
import Progress

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


public class Ingester {

    enum IngesterError: Swift.Error {
        case fileLoadError
        case badJson
        case audioAssetFail
        case artworkAssetFail
        case albumFail
        case songFail
        case singlesFail
    }

    public static func rubyIngest(runScript: Bool = true) throws {
        if (runScript) {
            let task = Process()
            task.launchPath = "./Script/ingest.rb"
            task.launch()
            task.waitUntilExit()
        }
        let data = FileManager.default.contents(atPath: "./Script/rb_ingest_data.json")
        guard data != nil else {
            throw IngesterError.fileLoadError
        }
        let jsonAry = try JSON.init(bytes: data!.makeBytes()).array
        guard jsonAry != nil else {
            throw IngesterError.badJson
        }
        var fileIndex = 0
        for file in Progress(jsonAry!) {
            let audioAsset = AudioAsset(json: file["audio_asset"])
            guard audioAsset != nil else {
                print("Failing JSON: \(file)")
                throw IngesterError.audioAssetFail
            }
            try audioAsset!.save()

            let artworkAsset: ImageAsset?
            let jsonArtworkAsset = file["artwork_asset"]?.object
            if let url = jsonArtworkAsset?["url"]?.string,
               let contentType = jsonArtworkAsset?["content_type"]?.string,
               let artworkAssetOpt = try? ImageAsset.findOrCreate(url: url, contentType: contentType) {
                artworkAsset = artworkAssetOpt
            } else {
//                print("Artwork Fail for: \(String(describing: file))")
                artworkAsset = nil
//                throw IngesterError.artworkAssetFail
            }

            var album: Album?
            if file["album"]?.string != nil && file["album"]?.string! != "" {
                let sortArtist: String
                if (file["artists"]?.array?.count ?? 0) > 0 {
                    sortArtist = file["artists"]?.array?[0].string ?? ""
                } else {
                    sortArtist = ""
                }
                album = try Album.findOrCreate(name: file["album"]!.string!,
                        sortArtist: sortArtist, year: file["song"]?["year"]?.int ?? 0,
                        artworkAssetId: artworkAsset?.id)
                guard album != nil else {
                    throw IngesterError.albumFail
                }
            } else {
//                print("Making Singles album for song: \(String(describing: file["song"])), with album \(String(describing: file["album"]))")
                if let ary = file["artists"]?.array,
                   ary.count > 0,
                   let artistName = file["artists"]?.array?[0].string,
                   let artist = try? Artist.findOrCreate(name: artistName) {
                    album = try Album.findOrCreate(singlesFor: artist)
                } else {
                    print("Single Fail Inbound for song[\(fileIndex)]: \(String(describing: file["artists"]))")
                    continue;
//                    throw IngesterError.singlesFail
                }
            }

            let song = Song(json: file["song"], album: album!.id!,
                    audioAssetId: audioAsset!.id!, artworkAssetId: artworkAsset?.id!)
            guard song != nil else {
                print(file)
                throw IngesterError.songFail
            }
            try song!.save()

            if let artists = file["artists"]?.array {
                for artist_name in artists {
                    let artist = try Artist.findOrCreate(name: artist_name.string!)
                    if try! !song!.artists.isAttached(artist) {
                        try song!.artists.add(artist)
                    }
                    if try! !album!.artists.isAttached(artist) {
                        try album!.artists.add(artist)
                    }
                }
            }
//            print(".", terminator: "")
//            fflush(stdout)
            fileIndex += 1
        }
        seed()
    }

    public static func seed() {
        seedPlaylist(songs: ["Cherenkov", "Jerall", "Journey's End", "A Winter's Tale", "Sky Above", "Aurora", "Wind Guide You",
                             "A Safe Place", "Dream Salvage", "Recreation", "Metaphysics", "0x10c", "The Process of Getting to Know You",
                             "Time Spent Wondering", "Inner Light", "Postcards from", "house_loneliness", "Seeds of the Crown", "The Winding Ridge",
                             "Acropolis Falls", "Panacea", "Easy Living", "Flim", "Variations On the Kanon"], name: "Bedtime")
        try? Search(":rating >= 3", name: "3+ Stars").save()
        try? Search(":rating >= 4", name: "4+ Stars").save()
        try? Search(":rating = 5", name: "5 Stars").save()
        try? Search("all", name: "all").save()

        if let pogoId = (try? Artist.makeQuery().filter("name", "Pogo").first()?.id?.int) ?? nil {
            print("@\(pogoId) and :rating >= 3")
            try? Search("@\(pogoId) and :rating >= 3", name: "Select Pogo").save()
        }
    }

    private static func seedPlaylist(songs: [String], name: String) {
        var query = ""
        for song in songs {
            try? query.append("$\(Song.makeQuery().filter("name", .contains, song).first()?.id?.int ?? 0), ")
        }
        print("Bedtime query: `\(query.substring(to: query.index(query.endIndex, offsetBy: -2)))`")
        let bedtime = try! Search(query.substring(to: query.index(query.endIndex, offsetBy: -2)), name: name)
        try! bedtime.save()
    }
}
