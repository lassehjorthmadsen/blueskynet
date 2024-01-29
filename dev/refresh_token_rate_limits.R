# Demo how to refresh token at expiry, and how
# to not break rate limits.

library(devtools)
library(tidyverse)
library(httr2)
load_all()

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")

#-----------------------------
# Refresh token
#-----------------------------

# We get tokens like this, a POST request with data:
req <-
  httr2::request('https://bsky.social/xrpc/com.atproto.server.createSession') |>
  httr2::req_body_json(data = list(identifier = identifier, password = password))

# The response contains token, refresh token and more
resp <- req |> httr2::req_perform()
resp |> str()
resp |> resp_body_json()

token <- resp$accessJwt
refresh_token <- resp$refreshJwt
my_handle <- resp$handle
my_did <- resp$did

# Refresh token when it expires (where do I see when that is?)
# Remember to turn the request into POST (done automatically when the
# request has a BODY, like in the `createSession` request above.
req <-
  httr2::request('https://bsky.social/xrpc/com.atproto.server.refreshSession') |>
  httr2::req_auth_bearer_token(token = refresh_token) |>
  req_method("POST")

resp <- req |> httr2::req_perform()
resp |> httr2::resp_body_json()





#-----------------------------
# Rate limits
#-----------------------------

# Some request;
req <- httr2::request('https://bsky.social/xrpc/app.bsky.graph.getFollows') |>
  httr2::req_url_query(actor = identifier, limit = 5) |>
  httr2::req_auth_bearer_token(token = token)

resp <- req |> httr2::req_perform()

# The response has 13 headers, one is "RateLimit-Remaining"
resp |> str()
resp |> resp_header("RateLimit-Remaining")
resp |> resp_header("RateLimit-Reset")

# When we reach the rate limit, we can check reset time and
# wait as nessecary
reset_time <- resp |>
  resp_header("RateLimit-Reset") |>
  as.numeric() |>
  as.POSIXct() # Using system time zone

Sys.timezone()
Sys.time()

check_wait(resp)


