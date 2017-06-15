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

public class Ingester {

    enum IngesterError: Error {
        case fileLoadError
        case badJson
        case mediaAssetFail
        case albumFail
        case songFail
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
            let mediaAsset = MediaAsset(json: file["media_asset"])
            guard mediaAsset != nil else {
                throw IngesterError.mediaAssetFail
            }
            try mediaAsset!.save()

            let album = try Album.findOrCreate(json: file["album"])
            guard album != nil else {
                throw IngesterError.albumFail
            }

            let song = Song(json: file["song"], album: album!.id!, audioAssetId: mediaAsset!.id!, artworkAssetId: nil)
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
            print(".", terminator: "")
        }
    }
}
