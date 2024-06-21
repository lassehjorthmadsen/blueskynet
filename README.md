
<!-- README.md is generated from README.Rmd. Please edit that file -->

# blueskynet

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/blueskynet)](https://CRAN.R-project.org/package=blueskynet)
<!-- badges: end -->

The purpose of blueskynet is to provide tools to generate and analyze
networks from Bluesky Social

## Installation

You can install the development version of blueskynet like so:

``` r
remotes::install_github("https://github.com/lassehjorthmadsen/blueskynet.git")
```

## Getting started

First, create an app password here:
<https://bsky.app/settings/app-passwords>.

Then, set environment variable BLUESKY_APP_PASS to your app password,
and another variable, BLUESKY_APP_USER, to your identifier
(e.g. “lassehjorthmadsen.bsky.social”) using `file.edit("~/.Renviron")`

Now, you can access the core function of blueskynet:

    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> New names:
    #> • `viewer.knownFollowers.followers.did` ->
    #>   `viewer.knownFollowers.followers.did...12`
    #> • `viewer.knownFollowers.followers.handle` ->
    #>   `viewer.knownFollowers.followers.handle...13`
    #> • `viewer.knownFollowers.followers.displayName` ->
    #>   `viewer.knownFollowers.followers.displayName...14`
    #> • `viewer.knownFollowers.followers.avatar` ->
    #>   `viewer.knownFollowers.followers.avatar...15`
    #> • `viewer.knownFollowers.followers.associated.chat.allowIncoming` ->
    #>   `viewer.knownFollowers.followers.associated.chat.allowIncoming...16`
    #> • `viewer.knownFollowers.followers.viewer.muted` ->
    #>   `viewer.knownFollowers.followers.viewer.muted...17`
    #> • `viewer.knownFollowers.followers.viewer.blockedBy` ->
    #>   `viewer.knownFollowers.followers.viewer.blockedBy...18`
    #> • `viewer.knownFollowers.followers.viewer.following` ->
    #>   `viewer.knownFollowers.followers.viewer.following...19`
    #> • `viewer.knownFollowers.followers.createdAt` ->
    #>   `viewer.knownFollowers.followers.createdAt...21`
    #> • `viewer.knownFollowers.followers.did` ->
    #>   `viewer.knownFollowers.followers.did...22`
    #> • `viewer.knownFollowers.followers.handle` ->
    #>   `viewer.knownFollowers.followers.handle...23`
    #> • `viewer.knownFollowers.followers.displayName` ->
    #>   `viewer.knownFollowers.followers.displayName...24`
    #> • `viewer.knownFollowers.followers.avatar` ->
    #>   `viewer.knownFollowers.followers.avatar...25`
    #> • `viewer.knownFollowers.followers.associated.chat.allowIncoming` ->
    #>   `viewer.knownFollowers.followers.associated.chat.allowIncoming...26`
    #> • `viewer.knownFollowers.followers.viewer.muted` ->
    #>   `viewer.knownFollowers.followers.viewer.muted...27`
    #> • `viewer.knownFollowers.followers.viewer.blockedBy` ->
    #>   `viewer.knownFollowers.followers.viewer.blockedBy...28`
    #> • `viewer.knownFollowers.followers.viewer.following` ->
    #>   `viewer.knownFollowers.followers.viewer.following...29`
    #> • `viewer.knownFollowers.followers.createdAt` ->
    #>   `viewer.knownFollowers.followers.createdAt...35`
    #> • `viewer.knownFollowers.followers.did` ->
    #>   `viewer.knownFollowers.followers.did...36`
    #> • `viewer.knownFollowers.followers.handle` ->
    #>   `viewer.knownFollowers.followers.handle...37`
    #> • `viewer.knownFollowers.followers.displayName` ->
    #>   `viewer.knownFollowers.followers.displayName...38`
    #> • `viewer.knownFollowers.followers.avatar` ->
    #>   `viewer.knownFollowers.followers.avatar...39`
    #> • `viewer.knownFollowers.followers.associated.chat.allowIncoming` ->
    #>   `viewer.knownFollowers.followers.associated.chat.allowIncoming...40`
    #> • `viewer.knownFollowers.followers.viewer.muted` ->
    #>   `viewer.knownFollowers.followers.viewer.muted...41`
    #> • `viewer.knownFollowers.followers.viewer.blockedBy` ->
    #>   `viewer.knownFollowers.followers.viewer.blockedBy...42`
    #> • `viewer.knownFollowers.followers.viewer.following` ->
    #>   `viewer.knownFollowers.followers.viewer.following...43`
    #> • `viewer.knownFollowers.followers.createdAt` ->
    #>   `viewer.knownFollowers.followers.createdAt...44`
    #> • `viewer.knownFollowers.followers.did` ->
    #>   `viewer.knownFollowers.followers.did...45`
    #> • `viewer.knownFollowers.followers.handle` ->
    #>   `viewer.knownFollowers.followers.handle...46`
    #> • `viewer.knownFollowers.followers.displayName` ->
    #>   `viewer.knownFollowers.followers.displayName...47`
    #> • `viewer.knownFollowers.followers.avatar` ->
    #>   `viewer.knownFollowers.followers.avatar...48`
    #> • `viewer.knownFollowers.followers.associated.chat.allowIncoming` ->
    #>   `viewer.knownFollowers.followers.associated.chat.allowIncoming...49`
    #> • `viewer.knownFollowers.followers.viewer.muted` ->
    #>   `viewer.knownFollowers.followers.viewer.muted...50`
    #> • `viewer.knownFollowers.followers.viewer.blockedBy` ->
    #>   `viewer.knownFollowers.followers.viewer.blockedBy...51`
    #> • `viewer.knownFollowers.followers.viewer.following` ->
    #>   `viewer.knownFollowers.followers.viewer.following...52`
    #> • `viewer.knownFollowers.followers.createdAt` ->
    #>   `viewer.knownFollowers.followers.createdAt...53`
    #> • `viewer.knownFollowers.followers.did` ->
    #>   `viewer.knownFollowers.followers.did...54`
    #> • `viewer.knownFollowers.followers.handle` ->
    #>   `viewer.knownFollowers.followers.handle...55`
    #> • `viewer.knownFollowers.followers.displayName` ->
    #>   `viewer.knownFollowers.followers.displayName...56`
    #> • `viewer.knownFollowers.followers.avatar` ->
    #>   `viewer.knownFollowers.followers.avatar...57`
    #> • `viewer.knownFollowers.followers.associated.chat.allowIncoming` ->
    #>   `viewer.knownFollowers.followers.associated.chat.allowIncoming...58`
    #> • `viewer.knownFollowers.followers.viewer.muted` ->
    #>   `viewer.knownFollowers.followers.viewer.muted...59`
    #> • `viewer.knownFollowers.followers.viewer.blockedBy` ->
    #>   `viewer.knownFollowers.followers.viewer.blockedBy...60`
    #> • `viewer.knownFollowers.followers.viewer.following` ->
    #>   `viewer.knownFollowers.followers.viewer.following...61`
    #> • `viewer.knownFollowers.followers.createdAt` ->
    #>   `viewer.knownFollowers.followers.createdAt...62`

First few rows of a starting point initial network:

``` r
small_net |> head(3)
#> # A tibble: 3 × 2
#>   actor_handle             follows_handle            
#>   <chr>                    <chr>                     
#> 1 natalieamiri.bsky.social dunjahayali.de            
#> 2 natalieamiri.bsky.social spiegelmagazin.bsky.social
#> 3 natalieamiri.bsky.social gildasahebi.bsky.social
```

Then you can expand the net, using `expand_net()` which we won’t run
here, since it can take a lot of time build a big network.
