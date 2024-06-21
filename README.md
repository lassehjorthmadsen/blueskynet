
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

``` r
library(blueskynet)
library(dplyr)

# Authenticate yourself
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Establish a small net as a starting point
key_actor <- "natalieamiri.bsky.social"
keywords <- c("reporter", "journalist", "writer")
small_net <- init_net(key_actor, keywords, token)
```

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
here, since it can take a lot of time to build a big network.

## Example application

Have a look at a network of influential scientists on Bluesky Social,
generated with `blueskynet`
[here](https://lassehjorthmadsen.github.io/blueskyanalyses/).
