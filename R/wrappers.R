#' Get token for Bluesky api
#'
#' @param identifier identifier for account
#' @param password app password
#'
#' @return response body
#' @export
#'
get_token <- function(identifier, password) {
  req <-
    httr2::request('https://bsky.social/xrpc/com.atproto.server.createSession') |>
    httr2::req_body_json(data = list(identifier = identifier, password = password))

  resp <- req |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  return(resp)
}


#' Refresh token for Bluesky api
#'
#' @param refresh_token character, refresh token
#'
#' @return response body
#' @export
#'
refresh_token <- function(refresh_token) {

  req <-
    httr2::request('https://bsky.social/xrpc/com.atproto.server.refreshSession') |>
    httr2::req_auth_bearer_token(token = refresh_token) |>
    httr2::req_method("POST")

  resp <- req |> httr2::req_perform()
  check_wait(resp)
  resp <- resp |> httr2::resp_body_json()

  return(resp)
}


#' Get follows for an actor
#'
#' @param actor account identifier
#' @param token token for api
#'
#' @return tibble with response information
#' @export
#'
#' @section Lexicon references:
#' [lexicons/app/bsky/graph/getFollows.json](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollows.json)
#'
get_follows <- function(actor, token) {

  # Get follows (first 100)
  req <- httr2::request('https://bsky.social/xrpc/app.bsky.graph.getFollows') |>
    httr2::req_url_query(actor = actor, limit = 100) |>
    httr2::req_auth_bearer_token(token = token)

  # HTTP 400 Bad Request can happen if we try to look up a non-existing (deleted) actor
  resp <- tryCatch(
    req |> httr2::req_perform() ,
    httr2_http_400 = function(cnd) return(NULL),
    httr2_http_500 = function(cnd) return(NULL)
  )

  if (!is.null(resp)) {
    check_wait(resp)
    resp <- resp |> httr2::resp_body_json()
  }

  # Extract the follows and store in data frame
  df <- resp |> resp2df(element = "follows")

  # Run loop until the cursor is undefined
  while(!is.null(resp$cursor)) {
    req <- req |> httr2::req_url_query(cursor = resp$cursor)

    # HTTP 400 Bad Request: can happen if we try to look up a non-existing (deleted) actor
    # HTTP 500 Internal Server Error: happens annoyingly now and then for unknown reasons
    # HTTP 502 Bad Gateway: also can happen
    resp <- tryCatch(
      req |> httr2::req_perform(),
      httr2_http_400 = function(cnd) return(NULL),
      httr2_http_500 = function(cnd) return(NULL),
      httr2_http_502 = function(cnd) return(NULL)
    )

    if (!is.null(resp)) {
      check_wait(resp)
      resp <- resp |> httr2::resp_body_json()
    }

    follows_chunk <- resp |> resp2df(element = "follows")

    df <- dplyr::bind_rows(df, follows_chunk)
  }

  return(df)
}

#' Get profile for an actor/actors
#'
#' @param actors character, actor handle
#' @param token character, api token
#' @param chunksize integer, the number of actors per request;
#'     defaults to 25, currently the maximum number allowed
#' @return tibble with profiles
#' @export
#'
get_profiles <- function(actors, token, chunksize = 25) {

  actors_chunks <- split(actors, ceiling(seq_along(actors) / chunksize))
  actors_list <- actors_chunks |> purrr::map(~ purrr::set_names(as.list(.x), 'actors'))

  req <- httr2::request('https://bsky.social/xrpc/app.bsky.actor.getProfiles') |>
    httr2::req_auth_bearer_token(token = token)

  resps <- actors_list |>
    purrr::map(~ httr2::req_url_query(req, !!!.x) |>
                 httr2::req_perform() |>
                 check_wait() |>
                 httr2::resp_body_json(),
               .progress = list(name = "   Getting profiles", clear = FALSE))

  df  <- resps |> purrr::map_dfr(resp2df, element = "profiles")

  return(df)
}


#' Follow an actor or actors
#'
#' @param my_did character, did-identification of the actor that wants to follow someone
#' @param actor_did character, did-identification of the actor to be followed
#' @param token token for api
#'
#' @return response object
#' @export
#'

follow_actor <- function(my_did, actor_did, token) {

  record <- list(
    "$type" = "app.bsky.graph.follow",
    "createdAt" = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    "subject" = actor_did
  )

  data <- list(
    repo = my_did,
    collection = "app.bsky.graph.follow",
    record = record
  )

  resp <-
    httr2::request("https://bsky.social/xrpc/com.atproto.repo.createRecord") |>
    httr2::req_body_json(data = data) |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_perform() |>
    check_wait()
    # httr2::resp_body_json()
    # maybe return the whole response, so we can examine headers?

  return(resp)
}
