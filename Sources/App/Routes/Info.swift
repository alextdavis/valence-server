import Vapor
import HTTP

class InfoRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.group("i") { g in
            g.group("song", Song.parameter) { b in
                b.get("url") { req in
                    let song: Song = try req.parameters.next(Song.self)
                    if let url = song.audioAsset?.url {
//                        print("file:///Users/alex/Music/iTunes/iTunes Music\(url)")
                        return Response(redirect: "//localhost:9292\(url)")
                    } else {
                        throw Abort(.notFound)
                    }
                }

                b.get("artwork") { req in
                    let song = try req.parameters.next(Song.self)
                    if let url = song.artworkAsset?.url as String? {
                        return Response(redirect: url)
                    } else {
                        throw Abort(.notFound)
                    }
                }

                b.get("json") { req in
                    return try req.parameters.next(Song.self).makeJSON()
                }

                b.get("infobox") { req in
                    let song = try req.parameters.next(Song.self)
                    return try self.view.make("song_infobox",
                            ["layout": false,
                             "@song": song.makeJSON()
                            ])
                }

                b.get("infotext") { req in
                    let song = try req.parameters.next(Song.self)
                    return "\(song.name)\n\(song.album!.name)–\(song.artist_str)"
                }

                b.get("info") { req in
                    //TODO: Move HTML routes to browse or something.
                    let song = try req.parameters.next(Song.self)
                    return try self.view.make("info_modal_song.erb",
                            ["layout": false,
                             "@song": song.makeJSON(),
                             "@artists": Artist.all().map({ $0.makeJSON() }),
                             "@albums": Album.all().map({ $0.makeJSON(.basic) })
                            ])
                }

                b.post("info") { req in
                    let song = try req.parameters.next(Song.self)
                    let data = req.data
                    guard (data["name"]?.string != nil && data["artists"]?.array != nil &&
                            data["album"]?.int != nil && data["track"]?.int != nil &&
                            data["lyrics"]?.string != nil && data["comment"]?.string != nil) else {
                        throw Abort.badRequest
                    }

                    let currentArtistsIds: [Int] =
                            (try song.artists.all()).map({ $0.id?.int }).removeNils()
                    let newArtistsIds: [Int] =
                            data["artists"]!.array?.map({ $0.int }).removeNils() ?? []
                    if (currentArtistsIds != newArtistsIds) {
                        for id in (currentArtistsIds.filter({ !newArtistsIds.contains($0) })) {
                            guard let artist = try Artist.find(id) else {
                                throw Abort.badRequest
                            }
                            try song.artists.remove(artist)
                        }
                        for id in (newArtistsIds.filter({ !currentArtistsIds.contains($0) })) {
                            guard let artist = try Artist.find(id) else {
                                throw Abort.badRequest
                            }
                            try song.artists.add(artist)
                        }
                    }

                    if song.albumId.int != data["album"]!.int {
                        if let newAlbum = try Album.find(data["album"]!.int) {
                            song.album = newAlbum
                        }
                    }

                    song.name = req.data["name"]!.string!
                    song.track = data["track"]!.int!
                    song.lyrics = data["lyrics"]!.string!
                    song.comment = data["comment"]!.string!

                    try song.save()
                    return ""
                }

                b.post("rank") { req in
                    let song = try req.parameters.next(Song.self)
                    if let newRank = req.data["rank"]?.int {
                        guard newRank >= 0 && newRank <= 3 else {
                            throw Abort.badRequest
                        }
                        song.rank = newRank
                        try song.save()
                    } else {
                        throw Abort.badRequest
                    }
                    return String(song.rank)
                }

                b.post("rating") { req in
                    let song = try req.parameters.next(Song.self)
                    if let newRating = req.data["rating"]?.int {
                        guard newRating >= 0 && newRating <= 5 else {
                            throw Abort.badRequest
                        }
                        song.rating = newRating
                        try song.save()
                    } else {
                        throw Abort.badRequest
                    }
                    return String(song.rating)
                }

                b.post("tags") { req in
                    let song = try req.parameters.next(Song.self)
                    guard req.data["tags"]?.array != nil else {
                        throw Abort.badRequest
                    }

                    let currentTagsIds: [Int] =
                            (try song.tags.all()).map({ $0.id?.int }).removeNils()
                    let newTagsIds: [Int] =
                            req.data["tags"]!.array?.map({ $0.int }).removeNils() ?? []
                    if (currentTagsIds != newTagsIds) {
                        for id in (currentTagsIds.filter({ !newTagsIds.contains($0) })) {
                            guard let tag = try Tag.find(id) else {
                                throw Abort.badRequest
                            }
                            try song.tags.remove(tag)
                        }
                        for id in (newTagsIds.filter({ !currentTagsIds.contains($0) })) {
                            guard let tag = try Tag.find(id) else {
                                throw Abort.badRequest
                            }
                            try song.tags.add(tag)
                        }
                    }
                    return "" //The HTML should come from a different place
                }
            }

            g.group("album", Album.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Album.self).makeJSON()
                }
            }

            g.group("artist", Artist.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Artist.self).makeJSON()
                }
            }

            g.group("tag", Tag.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Tag.self).makeJSON()
                }
            }

        }
    }
}
