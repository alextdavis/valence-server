import Foundation

extension Song {
    fileprivate func html(col: String) -> String {
        switch col {
        case "name":
            return self.name
        case "time":
            return String(format: "\(self.time / 60):%02d", self.time % 60)
        case "rating":
            var str = "<div class=\"rating\" data-value=\"\(self.rating)\"><div class=\"rating-static\">" +
                    "</div><div class=\"rating-active text-primary\">"
            for i in 0..<5 {
                str.append("<span data-num=\"\(5 - i)\">☆</span>")
            }
            str.append("</div></div>")
            return str
        case "artists":
            return (try? self.artists.all().map({ $0.html }).joined(separator: "&NegativeMediumSpace;")) ?? "Err!"
        case "album":
            return self.album?.html ?? "Err: No Album"
        case "year":
            return String(self.year)
        default:
            return "Song#html(col:) does not support column: `\(col)`"
        }
    }
}

extension Album {
    fileprivate var html: String {
        return "<a href=\"/i/album/\(self.id ?? "")\" class=\"label-album\">\(self.name)</a>"
    }
}

extension Artist {
    fileprivate var html: String {
        return "<a href=\"/i/artist/\(self.id ?? "")\"><span class=\"label-artist label\">" +
                "\(self.name.replacingOccurrences(of: " ", with: "&nbsp;"))</span></a>"
    }
}

extension Tag {
    fileprivate var html: String {
        return "<a href=\"/i/tag/\(self.id ?? "")\" class=\"label-tag\">\(self.name)</a>"
    }
}

public final class TableRender {
    private static let orderables = Set(["name", "year", "rating", "rank", "time", "play_count", "album"])

    static func render(songs: [Song], cols: [String], order: (String, String)?) throws -> String {
        var str = "<table class=\"songs-table table table-striped table-bordered table-condensed\"><thead><tr>"
        for col in cols {
            if col == "rank" {
                str.append("<td style=\"width: 30px\"></td>")
            } else if col == "track" {
                str.append("<td style=\"width: 20px;\">&numero;</td>")
            } else if TableRender.orderables.contains(col) {
                str.append("<td class=\"orderable-header\" style=\"text-align: right;\"" +
                        "data-col=\"\(col.lowercased())\"" +
                        "data-order=\"\(order != nil && order!.0 == col ? order!.1 : "")\">" +
                        "<span class=\"pull-left\">\(col.capitalized)</span>" +
                        "<i class=\"fa fa-sort\(order != nil && order!.0 == col ? "-" + order!.1 : "")\"></i></td>")
            } else {
                str.append("<td>\(col.capitalized)</td>")
            }
        }
        str.append("</tr></thead><tbody>")
        for song in songs {
            str.append("<tr data-id=\"\(try song.assertExists().int ?? 0)\">")
            for col in cols {
                switch col {
                case "rank":
                    str.append("<td class=\"row-rank\" data-rank=\"\(song.rank)\">")
                    str.append("<select style=\"display:none\" class=\"form-control input-sm rank-select\">")
                    for i in (0...3).reversed() {
                        str.append("<option \(song.rank == i ? "selected" : "") value=\"\(i)\">")
                        str.append(["Disable", "Suppress", "Neutral", "Promote"][i])
                        str.append("</option>")
                    }
                    str.append("</select>")
                    str.append("<i class=\"fa fa-\(["close", "chevron-down", "minus", "chevron-up"][song.rank])\"></i>")
                    str.append("</td>")
                case "tags":
                    str.append("<td class=\"row-tags\"><span class=\"tags-list\">")
                    str.append(try song.tags.all().map({ $0.html }).joined(separator: "&NegativeMediumSpace;"))
                    str.append("</span><i class=\"fa fa-pencil-square text-primary tag-edit\"></i>" +
                            "<span class=\"tags-edit\" style=\"display: none;\">" +
                            "<span style=\"width: calc(100% - 50px)\">" +
                            "<form class=\"tag-edit-form\" style=\"display: inline\">" +
                            "<select multiple class=\"form-control\" style=\"width: 80%\" name=\"tags[]\">")
                    for tag in try Tag.all() {
                        str.append("<option value=\"\(tag.name)\" \(try song.tags.isAttached(tag) ? "selected" : "")")
                        str.append(tag.name)
                        str.append("</option>")
                    }
                    str.append("</select></form></span>" +
                            "<button class=\"btn btn-primary tag-edit-done\">Done</button></span></td>")
                case "track":
                    str.append("<td class=\"row-track\"><i class=\"text-primary fa fa-info-circle\"></i><span>")
                    str.append(String(song.track))
                    str.append("</span></td>")
                default:
                    str.append("<td class=\"row-\(col)\">\(song.html(col: col))</td>")
                }
            }
            str.append("</tr>")
        }
        str.append("</tbody></table><script type=\"text/javascript\">" +
                "$('.row-tags select').select2({tags: true});</script>")
        //TODO: When a new tag is entered, it isn't added to the list of options in for other songs. Should be changed
        // so the select comes on-demand via ajax
        return str
    }
}
