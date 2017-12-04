# Valence Server

A Work-In-Progress web-based music library manager written in Swift

## Query Language for Music Searches

First, we have basic clauses for specific record IDs:
- `@` for artists
- `%` for albums
- `$` for songs
- `#` for tags

Ex:
```
@12
%82
$1187
#8
```
        "[@#$%]\\d+|,|and|or|not|:\\w+ (true|false)|:\\w+ [<>=!]=? \\d+|:\\w+ ([=~{] )?\"[^\"]+\"|\\(|\\)"
    "[@#$%]\\d+|,|and|or|not|:(\\w+) (true|false|([<>=!]=? )?(\\d+)|([=~{] )?(\"[^\"]+\"))|\\(|\\)".r
 
Next, we have named clauses, with operators and values

The format is as follows:
`:_field_ [operator] [value]`

The operator is optional, with equality being the default.  
The operators are: 
- `<`, `>`, `<=`, `>=` for comparison
- `=` & `!=` for (in)equality
- `~` for string Regular Expression match
- `{` for string contains

The value is either an integer, a double-quote delimited string, `true` or `false`.

Ex:
```
:year < 1992
:rating >= 3
:rating 5

:album_artist "foo bar"
:lyrics { "and"

```

Multiple clauses can be combined using boolean operators `and`, `or`, `not`, `xor`, and `nand`. 
A comma (`,`) is interpreted as an `or`.

Ex:
```
@12 and :rating >= 3
$1180, $234, $438, $12
not #7 or @39
```

Clauses can be encapsulated in parenthesis for order-of-operations purposes.

Ex: 
```
not (#7 and #8) or @9
```
