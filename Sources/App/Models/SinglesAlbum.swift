import Vapor
import FluentProvider
import HTTP

class SinglesAlbum: Album {
    let singlesAlbumArtist: Artist

    static func findOrCreate(for artist: Artist?) throws -> SinglesAlbum? {
        if artist == nil {
            return nil
        }
        if let album = ((try? self.makeQuery().filter("singles_album_artist" == artist!.id).first()) ?? nil) {
            print("found")
            return album
        } else {
            print("creating")
            let album: Album = SinglesAlbum(artist: artist!)
            try album.save()
            try album.artists.add(artist!)
            print("before create save")
            try album.save()
            print("after create save")
            return album as! SinglesAlbum
        }
    }

    init(artist: Artist) {
        self.singlesAlbumArtist = artist
        super.init(name: "\(artist.name) — Singles")
    }

    required init(row: Row) throws {
        if let artist = try Artist.find(row.get("singles_album_artist")) {
            self.singlesAlbumArtist = artist
            try super.init(row: row)
        } else {
            throw SomeError()
        }
    }

    override func makeRow() throws -> Row {
        var row = try super.makeRow()
        try row.set("singles_album_artist", singlesAlbumArtist.id!)
        return row
    }
}
