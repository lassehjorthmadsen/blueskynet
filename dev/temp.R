library(bskyr)

# renv::snapshot()
# set_bluesky_user("USERNAME.bsky.social", install = TRUE, r_env = file.path(Sys.getenv("HOME"), ".Renviron"))
# set_bluesky_pass("APP_PASSWORD", install = TRUE, r_env = file.path(Sys.getenv("HOME"), ".Renviron"))

bs_auth(user = get_bluesky_user(), pass = get_bluesky_pass())

bs_get_profile("lassehjorthmadsen")


# user <- get_bluesky_user()
# pass <- get_bluesky_pass()

has_bluesky_pass()

prof <- bs_get_profile("lassehjorthmadsen.bsky.social")

prof <- bs_get_profile("mkeyoung.bsky.social")

foll <- bs_get_follows("mkeyoung.bsky.social", limit = 1000)


### Will this work? In Python/VSCode, I get the infamous SSL certificate error

library(httr)
library(jsonlite)
library(bskyr)

HANDLE <- 'lassehjorthmadsen.bsky.social'
DID_URL <- 'https://bsky.social/xrpc/com.atproto.identity.resolveHandle'
APP_PASSWORD <- get_bluesky_pass()
API_KEY_URL <- 'https://bsky.social/xrpc/com.atproto.server.createSession'
FEED_URL <- 'https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed'
POST_FEED_URL <- 'https://bsky.social/xrpc/com.atproto.repo.createRecord'

bluesky_social <- function() {
  # 1. we resolve handle
  handle_url <- paste0(DID_URL, "?handle=", HANDLE)
  handle_rep <- GET(handle_url)
  did <- fromJSON(content(handle_rep, "text"))$did
  print(did)
  
  # 2. We get Token
  token_data <- list(identifier = did, password = APP_PASSWORD)
  token_headers <- c('Content-Type' = 'application/json')
  token_rep <- POST(API_KEY_URL, body = toJSON(token_data), headers = token_headers)
  token <- fromJSON(content(token_rep, "text"))$accessJwt
  print(token)
}

bluesky_social()


# Demo how to get follows without bskyr, using httr2
# from https://github.com/christopherkenny/bskyr/blob/main/R/auth.R

library(httr2)
library(purrr)
library(dplyr)

actor <- "mkeyoung.bsky.social"
user <- "lassehjorthmadsen.bsky.social"
pass <- readLines("c:/Users/LMDN/getbluenet_secrets/app_password.txt")

# Get token
req <- httr2::request('https://bsky.social/xrpc/com.atproto.server.createSession') |>
  httr2::req_body_json(
    data = list(
      identifier = user, password = pass
    )
  )

resp <- req |>
  httr2::req_perform() |>
  httr2::resp_body_json() 

token <- resp$accessJwt


# Get follows (first 100)
req <- httr2::request('https://bsky.social/xrpc/app.bsky.graph.getFollows') |>
  httr2::req_url_query(actor = actor, limit = 100) |>
  httr2::req_auth_bearer_token(token = token) 

resp <- req |>
  httr2::req_perform() |>
  httr2::resp_body_json()

# Extract the follows and store in data frame
all_follows <- resp |> pluck("follows") |> map(flatten) |> map_dfr(as_tibble)

# Run loop until the cursor is undefined
while(!is.null(resp$cursor)) {
  req <- req |> httr2::req_url_query(cursor = resp$cursor)
  
  resp <- req |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  
  temp <- resp |> pluck("follows") |> map(flatten) |> map_dfr(as_tibble)
  all_follows <- bind_rows(all_follows, temp)
}
