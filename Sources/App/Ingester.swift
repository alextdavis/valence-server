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
import CryptoSwift

public class Ingester {

    enum IngesterError: Error {
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
        for file in jsonAry! {
            let audioAsset = MediaAsset(json: file["audio_asset"])
            guard audioAsset != nil else {
                print("Failing JSON: \(file)")
                throw IngesterError.audioAssetFail
            }
            try audioAsset!.save()

            let artworkAsset: MediaAsset?
            let jsonArtworkAsset = file["artwork_asset"]?.object
            if let url = jsonArtworkAsset?["url"]?.string,
               let contentType = jsonArtworkAsset?["content_type"]?.string,
               let artworkAssetOpt = try? MediaAsset.findOrCreate(url: url, contentType: "image/jpeg") {
                artworkAsset = artworkAssetOpt
            } else {
                print("Artwork Fail for: \(String(describing: file))")
                artworkAsset = nil
//                throw IngesterError.artworkAssetFail
            }

            var album: Album?
            if file["album"]?.string != nil && file["album"]?.string! != "" {
                album = try Album.findOrCreate(name: file["album"]!.string!, artworkAssetId: artworkAsset?.id)
                guard album != nil else {
                    throw IngesterError.albumFail
                }
            } else {
                print("Making Singles album for song: \(file["song"]), with album \(file["album"])")
                if let ary = file["artists"]?.array,
                   ary.count > 0,
                   let artistName = file["artists"]?.array?[0].string,
                   let artist = try? Artist.findOrCreate(name: artistName) {
                    album = try SinglesAlbum.findOrCreate(for: artist)
                } else {
                    print("Single Fail Inbound for song: \(String(describing: file["artists"]))")
                    throw IngesterError.singlesFail
                }
            }

            let song = Song(json: file["song"], album: album!.id!,
                    audioAssetId: audioAsset!.id!, artworkAssetId: artworkAsset?.id!)
            guard song != nil else {
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
        }
    }
}
