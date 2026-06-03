# Shorten a BANC Neuroglancer URL

Posts a Neuroglancer scene to the public `nglstate` server and returns a
short Spelunker URL that round-trips the full state via a server-side
state id. Useful for sharing scenes (e.g. embedding them in articles or
sending them in chat) without the kilobyte-scale fragment that a fully
inline-encoded scene carries.

## Usage

``` r
banc_shorturl(
  x,
  baseurl = NULL,
  cache = TRUE,
  state_server = "https://global.daf-apis.com/nglstate/post",
  ...
)
```

## Arguments

- x:

  Either a fragment-encoded Neuroglancer URL (character) or an `ngscene`
  object as returned by
  [`fafbseg::ngl_decode_scene()`](https://rdrr.io/pkg/fafbseg/man/ngl_decode_scene.html).

- baseurl:

  Optional override for the Spelunker base URL. Defaults to the public
  BANC instance.

- cache:

  Logical; cache the POST so repeated calls in the same session don't
  re-hit the state server.

- state_server:

  URL of the Neuroglancer state-storage endpoint.

- ...:

  Passed to
  [`fafbseg::ngl_encode_url()`](https://rdrr.io/pkg/fafbseg/man/ngl_encode_url.html).

## Value

A character short URL of the form
`https://spelunker.cave-explorer.org/#!middleauth+https://global.daf-apis.com/nglstate/api/v1/<id>`.

## Examples

``` r
if (FALSE) { # \dontrun{
u <- banc_scene()
short <- banc_shorturl(u)
} # }
```
