library(httr2)
library(jsonlite)
devtools::load_all()

BLUESKY_APP_PASSWORD <- Sys.getenv("BLUESKY_APP_PASS")
BLUESKY_HANDLE <- "lassehjorthmadsen.bsky.social"

# Get token
req <-
  httr2::request('https://bsky.social/xrpc/com.atproto.server.createSession') |>
  httr2::req_body_json(data = list(identifier = BLUESKY_HANDLE, password = BLUESKY_APP_PASSWORD))

resp <- req |>
  httr2::req_perform() |>
  httr2::resp_body_json()

token <- resp$accessJwt
my_did <- resp$did

# Make post
post <- list(
  "$type" = "app.bsky.feed.post",
  "text" = "Trying to post this again from R",
  "createdAt" = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
)

data = list(
  repo = my_did,
  collection = "app.bsky.feed.post",
  record = post
)

# https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/createRecord.json"

req <-
  httr2::request("https://bsky.social/xrpc/com.atproto.repo.createRecord") |>
  httr2::req_body_json(data = data) %>%
  httr2::req_auth_bearer_token(token = token)

resp <- req |>
  httr2::req_perform() |>
  httr2::resp_body_json()

# Try to follow someone
mike <- get_profiles("mkeyoung.bsky.social", token)
follow_did <- mike$did

follow_record <- list(
  "$type" = "app.bsky.graph.follow",
  "createdAt" = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
  "subject" = follow_did
)

follow_data <- list(
  repo = my_did,
  collection = "app.bsky.graph.follow",
  record = follow_record
)

req_follow <-
  httr2::request("https://bsky.social/xrpc/com.atproto.repo.createRecord") %>%
  httr2::req_body_json(data = follow_data) %>%
  httr2::req_auth_bearer_token(token = token) %>%
  httr2::req_perform()


# From: https://github.com/bluesky-social/atproto/discussions/1707
# Add-AtprotoRepoRecord -Repo $myBlueSkySession.did -Collection 'app.bsky.graph.follow' -Record ([PSCustomObject][Ordered]@{
#   '$type' = 'app.bsky.graph.follow'
#   createdAt = [DateTime]::Now.ToString('o')
#   subject=$this.did
# })
