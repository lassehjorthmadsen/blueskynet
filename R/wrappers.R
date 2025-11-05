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


#' Unfollow an actor using record key
#'
#' @param my_did character, did-identification of the actor that wants to unfollow someone
#' @param rkey character, record key of the follow relationship to delete
#' @param token character, api token
#'
#' @return response object
#' @export
#'
unfollow_actor <- function(my_did, rkey, token) {

  data <- list(
    repo = my_did,
    collection = "app.bsky.graph.follow",
    rkey = rkey
  )

  resp <- httr2::request("https://bsky.social/xrpc/com.atproto.repo.deleteRecord") |>
    httr2::req_body_json(data = data) |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_perform() |>
    check_wait()

  return(resp)
}


#' Verify token
#'
#' @param token, character, api token
#'
#' @return boolean, is the token valid (TRUE) or not (FALSE)?
#' @export
#'
verify_token <- function(token) {
  req <- httr2::request("https://bsky.social/xrpc/com.atproto.server.getSession") |>
    httr2::req_auth_bearer_token(token = token)

  tryCatch({
    resp <- req |> httr2::req_perform()
    status <- httr2::resp_status(resp)

    if (status == 200) {
      body <- httr2::resp_body_json(resp)
      message("Token is valid. Associated with handle: ", body$handle)
      return(TRUE)
    } else {
      message("Token appears to be invalid. Status code: ", status)
      return(FALSE)
    }
  }, error = function(e) {
    message("Error occurred while verifying token: ", e$message)
    return(FALSE)
  })
}






#' Get follows for an actor with improved error handling
#'
#' @param actor account identifier
#' @param token token for api
#' @param max_retries number of times to retry on failure (default 3)
#' @param retry_delay delay in seconds between retries (default 5)
#'
#' @return tibble with response information
#' @export
get_follows <- function(actor, token, max_retries = 3, retry_delay = 5) {
  attempt_request <- function(req, attempt = 1) {
    if (attempt > max_retries) {
      warning(sprintf("Max retries (%d) reached for actor: %s", max_retries, actor))
      return(NULL)
    }

    tryCatch({
      resp <- req |> httr2::req_perform()
      check_wait(resp)
      return(resp)
    },
    httr2_http_400 = function(cnd) {
      warning(sprintf("Bad request for actor %s (possibly deleted)", actor))
      return(NULL)
    },
    httr2_http_500 = function(cnd) {
      warning("Server error (500), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_502 = function(cnd) {
      warning("Bad gateway (502), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_504 = function(cnd) {
      warning("Gateway timeout (504), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    error = function(e) {
      if (grepl("timeout|SSL/TLS connection timeout", e$message)) {
        warning("Connection timeout, retrying...")
        Sys.sleep(retry_delay)
        return(attempt_request(req, attempt + 1))
      }
      warning(sprintf("Unexpected error: %s", e$message))
      return(NULL)
    })
  }

  # Get follows (first 100)
  req <- httr2::request('https://bsky.social/xrpc/app.bsky.graph.getFollows') |>
    httr2::req_url_query(actor = actor, limit = 100) |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_timeout(seconds = 30) # Add explicit timeout

  resp <- attempt_request(req)
  if (is.null(resp)) return(NULL)

  resp <- resp |> httr2::resp_body_json()
  df <- resp |> resp2df(element = "follows")

  while(!is.null(resp$cursor)) {
    req <- req |> httr2::req_url_query(cursor = resp$cursor)
    resp_next <- attempt_request(req)

    if (is.null(resp_next)) {
      warning("Failed to get next page, returning partial results")
      break
    }

    resp <- resp_next |> httr2::resp_body_json()
    follows_chunk <- resp |> resp2df(element = "follows")
    df <- dplyr::bind_rows(df, follows_chunk)
  }

  return(df)
}


#' Get followers for an actor
#'
#' @param actor account identifier
#' @param token token for api
#' @param max_retries number of times to retry on failure (default 3)
#' @param retry_delay delay in seconds between retries (default 5)
#'
#' @return tibble with response information
#' @export
#'
#' @section Lexicon references:
#' [lexicons/app/bsky/graph/getFollowers.json](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollowers.json)
#'
get_followers <- function(actor, token, max_retries = 3, retry_delay = 5) {
  attempt_request <- function(req, attempt = 1) {
    if (attempt > max_retries) {
      warning(sprintf("Max retries (%d) reached for actor: %s", max_retries, actor))
      return(NULL)
    }

    tryCatch({
      resp <- req |> httr2::req_perform()
      check_wait(resp)
      return(resp)
    },
    httr2_http_400 = function(cnd) {
      warning(sprintf("Bad request for actor %s (possibly deleted)", actor))
      return(NULL)
    },
    httr2_http_500 = function(cnd) {
      warning("Server error (500), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_502 = function(cnd) {
      warning("Bad gateway (502), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_504 = function(cnd) {
      warning("Gateway timeout (504), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    error = function(e) {
      if (grepl("timeout|SSL/TLS connection timeout", e$message)) {
        warning("Connection timeout, retrying...")
        Sys.sleep(retry_delay)
        return(attempt_request(req, attempt + 1))
      }
      warning(sprintf("Unexpected error: %s", e$message))
      return(NULL)
    })
  }

  # Get followers (first 100)
  req <- httr2::request('https://bsky.social/xrpc/app.bsky.graph.getFollowers') |>
    httr2::req_url_query(actor = actor, limit = 100) |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_timeout(seconds = 30) # Add explicit timeout

  resp <- attempt_request(req)
  if (is.null(resp)) return(NULL)

  resp <- resp |> httr2::resp_body_json()
  df <- resp |> resp2df(element = "followers")

  while(!is.null(resp$cursor)) {
    req <- req |> httr2::req_url_query(cursor = resp$cursor)
    resp_next <- attempt_request(req)

    if (is.null(resp_next)) {
      warning("Failed to get next page, returning partial results")
      break
    }

    resp <- resp_next |> httr2::resp_body_json()
    followers_chunk <- resp |> resp2df(element = "followers")
    df <- dplyr::bind_rows(df, followers_chunk)
  }

  return(df)
}


#' Get profile for an actor/actors with improved error handling
#'
#' @param actors character, actor handle
#' @param token character, api token
#' @param chunksize integer, the number of actors per request
#' @param max_retries number of times to retry on failure (default 3)
#' @param retry_delay delay in seconds between retries (default 5)
#' @return tibble with profiles
#' @export
get_profiles <- function(actors, token, chunksize = 25, max_retries = 3, retry_delay = 5) {
  actors_chunks <- split(actors, ceiling(seq_along(actors) / chunksize))
  actors_list <- actors_chunks |> purrr::map(~ purrr::set_names(as.list(.x), 'actors'))

  req <- httr2::request('https://bsky.social/xrpc/app.bsky.actor.getProfiles') |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_timeout(seconds = 30) # Add explicit timeout

  # Function to handle a single chunk with retries
  handle_chunk <- function(chunk, attempt = 1) {
    if (attempt > max_retries) {
      warning(sprintf("Max retries (%d) reached for chunk", max_retries))
      return(NULL)
    }

    tryCatch({
      resp <- httr2::req_url_query(req, !!!chunk) |>
        httr2::req_perform()
      check_wait(resp)
      return(httr2::resp_body_json(resp))
    },
    httr2_http_500 = function(cnd) {
      warning("Server error (500), retrying...")
      Sys.sleep(retry_delay)
      return(handle_chunk(chunk, attempt + 1))
    },
    httr2_http_502 = function(cnd) {
      warning("Bad gateway (502), retrying...")
      Sys.sleep(retry_delay)
      return(handle_chunk(chunk, attempt + 1))
    },
    httr2_http_504 = function(cnd) {
      warning("Gateway timeout (504), retrying...")
      Sys.sleep(retry_delay)
      return(handle_chunk(chunk, attempt + 1))
    },
    error = function(e) {
      if (grepl("timeout|SSL/TLS connection timeout", e$message)) {
        warning("Connection timeout, retrying...")
        Sys.sleep(retry_delay)
        return(handle_chunk(chunk, attempt + 1))
      }
      warning(sprintf("Unexpected error: %s", e$message))
      return(NULL)
    })
  }

  # Process chunks with progress bar
  resps <- actors_list |>
    purrr::map(handle_chunk,
               .progress = list(name = "   Getting profiles", clear = FALSE))

  # Remove NULL responses and combine results
  resps <- resps[!sapply(resps, is.null)]
  df <- resps |> purrr::map_dfr(resp2df, element = "profiles")

  return(df)
}


#' Get posts from a specific user
#'
#' @param actor character, the handle or DID of the user
#' @param token character, authentication token
#' @param filter character, posts to filter for. Possible values
#' "posts_with_replies", "posts_no_replies", "posts_with_media",
#' "posts_and_author_threads", "posts_with_video."
#' @param max_retries integer, maximum number of retries
#' @param retry_delay real, delay in seconds between retries
#' @param limit integer, max number of posts
#' @param return_df boolean, return responses as tibble
#' @return tibble or json string with posts information
#' @seealso [Endpoint documentation](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/feed/getAuthorFeed.json)
#' @export
get_user_posts <- function(actor, token, max_retries = 3, retry_delay = 5, filter = "posts_no_replies", limit = 100, return_df = TRUE) {
  attempt_request <- function(req, attempt = 1) {
    if (attempt > max_retries) {
      warning(sprintf("Max retries (%d) reached for actor: %s", max_retries, actor))
      return(NULL)
    }

    tryCatch({
      resp <- req |> httr2::req_perform()
      check_wait(resp)
      return(resp)
    },
    httr2_http_400 = function(cnd) {
      warning(sprintf("Bad request for actor %s (possibly deleted)", actor))
      return(NULL)
    },
    httr2_http_500 = function(cnd) {
      warning("Server error (500), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_502 = function(cnd) {
      warning("Bad gateway (502), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_504 = function(cnd) {
      warning("Gateway timeout (504), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    error = function(e) {
      if (grepl("timeout|SSL/TLS connection timeout", e$message)) {
        warning("Connection timeout, retrying...")
        Sys.sleep(retry_delay)
        return(attempt_request(req, attempt + 1))
      }
      warning(sprintf("Unexpected error: %s", e$message))
      return(NULL)
    })
  }

  # Setup request
  req <- httr2::request('https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed') |>
    httr2::req_url_query(actor = actor, filter = filter, limit = limit) |>
    httr2::req_auth_bearer_token(token = token) |>
    httr2::req_timeout(seconds = 30)

  # Get first batch of posts
  message("Fetching posts...", appendLF = FALSE)
  resp <- attempt_request(req)
  if (is.null(resp)) return(NULL)

  # Convert to json
  resp <- resp |> httr2::resp_body_json()

  # Store responses in list
  all_resp <- list()
  all_resp <- append(all_resp, resp)

  # Paginate through remaining posts
  page_count <- 1
  while(!is.null(resp$cursor)) {
    Sys.sleep(0.5)  # Half second delay between requests
    page_count <- page_count + 1
    message(".", appendLF = FALSE)  # Simple progress indicator

    req <- req |> httr2::req_url_query(cursor = resp$cursor)
    resp <- attempt_request(req)

    if (is.null(resp)) {
      message("\n! Failed to get next page, returning partial results")
      break
    }

    resp <- resp |> httr2::resp_body_json()
    all_resp <- append(all_resp, resp)

    # Print newline and count every 50 pages
    if (page_count %% 50 == 0) {
      message(" ", page_count)
    }
  }

  message("\nFetched ", page_count, " pages")

  # Convert to dataframe if requested
  if (return_df) {
    df <- post2df(actor = actor, response = all_resp, element = "feed")
    return(df)
  } else {
    return(all_resp)
  }
}


#' Get all follow records from user's repository
#'
#' @param my_did character, did-identification of the user
#' @param token character, api token
#' @param max_retries integer, maximum number of retries on failure
#' @param retry_delay numeric, delay in seconds between retries
#'
#' @return list of all follow records with uri, cid, and value fields
#' @export
#'
get_all_follow_records <- function(my_did, token, max_retries = 3, retry_delay = 5) {

  attempt_request <- function(req, attempt = 1) {
    if (attempt > max_retries) {
      warning(sprintf("Max retries (%d) reached", max_retries))
      return(NULL)
    }

    tryCatch({
      resp <- req |> httr2::req_perform()
      check_wait(resp)
      return(resp)
    },
    httr2_http_500 = function(cnd) {
      warning("Server error (500), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    httr2_http_502 = function(cnd) {
      warning("Bad gateway (502), retrying...")
      Sys.sleep(retry_delay)
      return(attempt_request(req, attempt + 1))
    },
    error = function(e) {
      warning(sprintf("Error: %s", e$message))
      return(NULL)
    })
  }

  # Get all follow records with pagination
  all_records <- list()
  cursor <- NULL
  page_count <- 0

  message("Fetching follow records...", appendLF = FALSE)

  repeat {
    page_count <- page_count + 1

    req <- httr2::request("https://bsky.social/xrpc/com.atproto.repo.listRecords") |>
      httr2::req_url_query(
        repo = my_did,
        collection = "app.bsky.graph.follow",
        limit = 100
      ) |>
      httr2::req_auth_bearer_token(token = token) |>
      httr2::req_timeout(seconds = 30)

    if (!is.null(cursor)) {
      req <- req |> httr2::req_url_query(cursor = cursor)
    }

    resp <- attempt_request(req)
    if (is.null(resp)) {
      warning("Failed to get follow records page ", page_count)
      break
    }

    follows_data <- httr2::resp_body_json(resp)
    all_records <- c(all_records, follows_data$records)

    message(".", appendLF = FALSE)

    if (is.null(follows_data$cursor)) {
      break
    }
    cursor <- follows_data$cursor

    # Progress indicator every 50 pages
    if (page_count %% 50 == 0) {
      message(" ", page_count)
    }
  }

  message("\nFetched ", length(all_records), " follow records from ", page_count, " pages")

  return(all_records)
}


#' Extract subject DIDs from follow records
#'
#' @param follow_records list, output from get_all_follow_records()
#'
#' @return character vector of DIDs
#' @export
#'
extract_follow_subjects <- function(follow_records) {
  sapply(follow_records, function(record) record$value$subject)
}


#' Find follow record for specific actor
#'
#' @param follow_records list, output from get_all_follow_records()
#' @param actor_did character, DID to search for
#'
#' @return single follow record or NULL if not found
#' @export
#'
find_follow_record <- function(follow_records, actor_did) {
  for (record in follow_records) {
    if (record$value$subject == actor_did) {
      return(record)
    }
  }
  return(NULL)
}
