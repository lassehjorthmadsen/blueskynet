
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
<https://bsky.app/settings/app-passwords>. Then, set environment
variable BLUESKY_APP_PASS to your app password, and another variable,
BLUESKY_APP_USER, to your identifier
(e.g. “lassehjorthmadsen.bsky.social”) using file.edit(“~/.Renviron”)

Now, you can access the core function of blueskynet:

``` r
library(blueskynet)

# Authenticate yourself
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Establish a small net as a starting point
key_actor <- "slooterman.bsky.social"
keywords <- c("reporter", "journalist", "writer")
small_net <- init_net(key_actor, keywords, token)
#>    Getting profiles ■■■■■                             14% |  ETA:  7s   Getting profiles ■■■■■■                            16% |  ETA:  7s   Getting profiles ■■■■■■■                           19% |  ETA:  7s   Getting profiles ■■■■■■■                           21% |  ETA:  7s   Getting profiles ■■■■■■■■                          23% |  ETA:  7s   Getting profiles ■■■■■■■■■                         26% |  ETA:  6s   Getting profiles ■■■■■■■■■                         28% |  ETA:  6s   Getting profiles ■■■■■■■■■■                        30% |  ETA:  6s   Getting profiles ■■■■■■■■■■■                       33% |  ETA:  6s   Getting profiles ■■■■■■■■■■■                       35% |  ETA:  5s   Getting profiles ■■■■■■■■■■■■■                     40% |  ETA:  5s   Getting profiles ■■■■■■■■■■■■■■                    42% |  ETA:  5s   Getting profiles ■■■■■■■■■■■■■■                    44% |  ETA:  5s   Getting profiles ■■■■■■■■■■■■■■■■                  49% |  ETA:  4s   Getting profiles ■■■■■■■■■■■■■■■■                  51% |  ETA:  4s   Getting profiles ■■■■■■■■■■■■■■■■■                 53% |  ETA:  4s   Getting profiles ■■■■■■■■■■■■■■■■■■                56% |  ETA:  4s   Getting profiles ■■■■■■■■■■■■■■■■■■                58% |  ETA:  4s   Getting profiles ■■■■■■■■■■■■■■■■■■■               60% |  ETA:  3s   Getting profiles ■■■■■■■■■■■■■■■■■■■■              63% |  ETA:  3s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■             67% |  ETA:  3s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■            70% |  ETA:  3s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■           72% |  ETA:  2s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■           74% |  ETA:  2s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■          77% |  ETA:  2s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■         79% |  ETA:  2s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■         81% |  ETA:  2s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■       86% |  ETA:  1s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■      88% |  ETA:  1s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■      91% |  ETA:  1s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■     93% |  ETA:  1s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■    95% |  ETA:  0s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■    98% |  ETA:  0s   Getting profiles ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% |  ETA:  0s
#> Warning: The `x` argument of `as_tibble.matrix()` must have unique column names if
#> `.name_repair` is omitted as of tibble 2.0.0.
#> ℹ Using compatibility `.name_repair`.
#> ℹ The deprecated feature was likely used in the purrr package.
#>   Please report the issue at <https://github.com/tidyverse/purrr/issues>.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

small_net |> head(3)
#> # A tibble: 3 × 2
#>   actor_handle           follows_handle           
#>   <chr>                  <chr>                    
#> 1 slooterman.bsky.social mcgowankat.bsky.social   
#> 2 slooterman.bsky.social profmusgrave.bsky.social 
#> 3 slooterman.bsky.social meghanbartels.bsky.social
```

Then you can expand the net, using `expand_net()` which we won’t run
here, since it can take a lot of time build a big network.
