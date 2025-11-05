#' Get authentication token for Bluesky API
#'
#' Authenticates with the Bluesky API using your handle and app password to obtain
#' access and refresh tokens for subsequent API calls.
#'
#' @param identifier Character. Your Bluesky handle (e.g., "username.bsky.social")
#'   or email address
#' @param password Character. Your Bluesky app password (not your regular password).
#'   Create one at https://bsky.app/settings/app-passwords
#'
#' @return A list containing authentication information:
#' \describe{
#'   \item{accessJwt}{Character. Access token for API calls}
#'   \item{refreshJwt}{Character. Refresh token for renewing access}
#'   \item{handle}{Character. Your verified handle}
#'   \item{did}{Character. Your decentralized identifier (DID)}
#'   \item{email}{Character. Your email address}
#' }
#'
#' @family authentication
#' @seealso \code{\link{refresh_token}}, \code{\link{verify_token}}
#'
#' @examples
#' \dontrun{
#' # Authenticate with Bluesky (requires valid credentials)
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#'
#' # Extract tokens for use in other functions
#' access_token <- auth$accessJwt
#' refresh_token <- auth$refreshJwt
#' my_did <- auth$did
#'
#' # Verify the token works
#' verify_token(access_token)
#' }
#'
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


#' Refresh authentication token for Bluesky API
#'
#' Refreshes an expired access token using a refresh token. Access tokens
#' expire after a period of time, but refresh tokens can be used to obtain
#' new access tokens without re-authenticating.
#'
#' @param refresh_token Character. The refresh token obtained from \code{\link{get_token}}
#'
#' @return A list containing new authentication information:
#' \describe{
#'   \item{accessJwt}{Character. New access token for API calls}
#'   \item{refreshJwt}{Character. New refresh token for future renewals}
#'   \item{handle}{Character. Your verified handle}
#'   \item{did}{Character. Your decentralized identifier (DID)}
#' }
#'
#' @family authentication
#' @seealso \code{\link{get_token}}, \code{\link{verify_token}}
#'
#' @examples
#' \dontrun{
#' # First authenticate to get tokens
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#'
#' # Later, when access token expires, refresh it
#' new_auth <- refresh_token(auth$refreshJwt)
#' new_access_token <- new_auth$accessJwt
#'
#' # Use the new token for API calls
#' profiles <- get_profiles("example.bsky.social", new_access_token)
#' }
#'
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


#' Follow a user on Bluesky Social
#'
#' Creates a follow relationship between your account and another user on
#' Bluesky Social. This is equivalent to clicking the "Follow" button on
#' a user's profile.
#'
#' @param my_did Character. Your decentralized identifier (DID) obtained from
#'   \code{\link{get_token}} response
#' @param actor_did Character. The DID of the user you want to follow. Can be
#'   obtained using \code{\link{get_profiles}}
#' @param token Character. Authentication token from \code{\link{get_token}}
#'
#' @return An httr2 response object containing:
#' \describe{
#'   \item{uri}{Character. URI of the created follow record}
#'   \item{cid}{Character. Content identifier for the follow record}
#' }
#'   Returns \code{NULL} if the follow operation fails.
#'
#' @family follow-management
#' @seealso \code{\link{unfollow_actor}}, \code{\link{get_follows}},
#'   \code{\link{get_profiles}}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' my_did <- auth$did
#'
#' # Get the DID of the user you want to follow
#' target_profile <- get_profiles("neilhimself.neilgaiman.com", token)
#' target_did <- target_profile$did
#'
#' # Follow the user
#' result <- follow_actor(my_did, target_did, token)
#'
#' if (!is.null(result)) {
#'   message("Successfully followed user!")
#' }
#'
#' # Follow multiple users
#' users_to_follow <- c("user1.bsky.social", "user2.bsky.social")
#' profiles <- get_profiles(users_to_follow, token)
#'
#' for (i in 1:nrow(profiles)) {
#'   result <- follow_actor(my_did, profiles$did[i], token)
#'   Sys.sleep(1) # Be respectful with rate limits
#' }
#' }
#'
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


#' Unfollow a user on Bluesky Social
#'
#' Removes a follow relationship between your account and another user on
#' Bluesky Social. This is equivalent to clicking the "Unfollow" button on
#' a user's profile. Requires the record key of the follow relationship.
#'
#' @param my_did Character. Your decentralized identifier (DID) obtained from
#'   \code{\link{get_token}} response
#' @param rkey Character. Record key of the follow relationship to delete.
#'   Can be obtained from \code{\link{get_all_follow_records}} or by parsing
#'   the URI from \code{\link{follow_actor}} response
#' @param token Character. Authentication token from \code{\link{get_token}}
#'
#' @return An httr2 response object confirming the deletion, or \code{NULL}
#'   if the unfollow operation fails.
#'
#' @family follow-management
#' @seealso \code{\link{follow_actor}}, \code{\link{get_all_follow_records}},
#'   \code{\link{find_follow_record}}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' my_did <- auth$did
#'
#' # Get all your follow records to find the one to delete
#' all_follows <- get_all_follow_records(my_did, token)
#'
#' # Find the record for a specific user
#' target_profile <- get_profiles("example.bsky.social", token)
#' target_record <- find_follow_record(all_follows, target_profile$did)
#'
#' if (!is.null(target_record)) {
#'   # Extract record key from URI (after the last slash)
#'   rkey <- basename(target_record$uri)
#'
#'   # Unfollow the user
#'   result <- unfollow_actor(my_did, rkey, token)
#'
#'   if (!is.null(result)) {
#'     message("Successfully unfollowed user!")
#'   }
#' }
#' }
#'
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


#' Verify authentication token validity
#'
#' Checks whether an access token is still valid by making a test API call
#' to the Bluesky session endpoint. This is useful for checking if a token
#' has expired before making other API calls.
#'
#' @param token Character. Authentication token from \code{\link{get_token}}
#'   or \code{\link{refresh_token}}
#'
#' @return Logical. Returns \code{TRUE} if the token is valid and active,
#'   \code{FALSE} if the token is invalid, expired, or revoked. Also prints
#'   a message with the associated handle if valid, or error details if invalid.
#'
#' @family authentication
#' @seealso \code{\link{get_token}}, \code{\link{refresh_token}}
#'
#' @examples
#' \dontrun{
#' # Authenticate and verify token
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Check if token is valid
#' is_valid <- verify_token(token)
#'
#' if (is_valid) {
#'   # Token is good, proceed with API calls
#'   profiles <- get_profiles("example.bsky.social", token)
#' } else {
#'   # Token expired, refresh it
#'   new_auth <- refresh_token(auth$refreshJwt)
#'   token <- new_auth$accessJwt
#' }
#'
#' # Can also use in conditional logic
#' if (!verify_token(token)) {
#'   stop("Please re-authenticate - your token has expired")
#' }
#' }
#'
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






#' Get accounts followed by a user
#'
#' Retrieves all accounts that a specific user follows on Bluesky Social.
#' Includes robust error handling and automatic retry logic for network issues.
#'
#' @param actor Character. User handle (e.g., "username.bsky.social") or DID
#'   of the account whose follows you want to retrieve
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param max_retries Integer. Number of times to retry on failure (default 3)
#' @param retry_delay Numeric. Delay in seconds between retries (default 5)
#'
#' @return A tibble with information about followed accounts:
#' \describe{
#'   \item{handle}{Character. The followed user's handle}
#'   \item{did}{Character. The followed user's DID}
#'   \item{displayName}{Character. The followed user's display name}
#'   \item{description}{Character. The followed user's bio}
#'   \item{followersCount}{Integer. Number of followers the followed user has}
#'   \item{followsCount}{Integer. Number of accounts the followed user follows}
#'   \item{createdAt}{Character. When the follow relationship was created}
#' }
#'
#' @family api-wrappers
#' @seealso \code{\link{get_followers}}, \code{\link{get_profiles}}
#'
#' @section Lexicon references:
#' \href{https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollows.json}{lexicons/app/bsky/graph/getFollows.json}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Get who Neil Gaiman follows
#' follows <- get_follows("neilhimself.neilgaiman.com", token)
#' head(follows)
#'
#' # Get follows for multiple users
#' users <- c("example1.bsky.social", "example2.bsky.social")
#' all_follows <- lapply(users, get_follows, token = token)
#' names(all_follows) <- users
#' }
#'
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


#' Get followers of a Bluesky user
#'
#' Retrieves all users who follow a specific account on Bluesky Social.
#' This is the inverse of \code{\link{get_follows}} - while that shows who
#' a user follows, this shows who follows them. Includes robust error handling
#' with automatic retries for reliable data collection.
#'
#' @param actor Character. User handle (e.g., "username.bsky.social") or DID
#'   of the account whose followers you want to retrieve
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param max_retries Integer. Number of times to retry on failure (default 3)
#' @param retry_delay Numeric. Delay in seconds between retries (default 5)
#'
#' @return A tibble with information about followers:
#' \describe{
#'   \item{handle}{Character. The follower's handle}
#'   \item{did}{Character. The follower's DID}
#'   \item{displayName}{Character. The follower's display name}
#'   \item{description}{Character. The follower's bio}
#'   \item{followersCount}{Integer. Number of followers the follower has}
#'   \item{followsCount}{Integer. Number of accounts the follower follows}
#'   \item{createdAt}{Character. When the follow relationship was created}
#' }
#'   Returns \code{NULL} if the user doesn't exist or is inaccessible.
#'
#' @family api-wrappers
#' @seealso \code{\link{get_follows}}, \code{\link{get_profiles}}
#'
#' @section Lexicon references:
#' \href{https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollowers.json}{lexicons/app/bsky/graph/getFollowers.json}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Get followers of a popular account
#' followers <- get_followers("neilhimself.neilgaiman.com", token)
#' print(paste("User has", nrow(followers), "followers"))
#'
#' # Analyze follower demographics
#' follower_profiles <- get_profiles(followers$handle[1:100], token)
#' print(summary(follower_profiles$followersCount))
#'
#' # Compare follows vs followers for reciprocity analysis
#' user_handle <- "example.bsky.social"
#' follows <- get_follows(user_handle, token)
#' followers <- get_followers(user_handle, token)
#'
#' # Find mutual connections (people who follow each other)
#' mutual <- intersect(follows$handle, followers$handle)
#' print(paste("Mutual connections:", length(mutual)))
#'
#' # Identify influential followers (high follower count)
#' influential <- followers[followers$followersCount > 1000, ]
#' head(influential[, c("displayName", "handle", "followersCount")])
#' }
#'
#' @export
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


#' Get profile information for Bluesky users
#'
#' Retrieves detailed profile information for one or more users on Bluesky Social.
#' Includes robust error handling with automatic retries and efficient batch processing
#' for multiple users.
#'
#' @param actors Character vector. User handles (e.g., "username.bsky.social") or
#'   DIDs of users whose profiles you want to retrieve
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param chunksize Integer. Number of actors per API request for batch processing
#'   (default 25, which is the current API maximum)
#' @param max_retries Integer. Number of times to retry on failure (default 3)
#' @param retry_delay Numeric. Delay in seconds between retries (default 5)
#'
#' @return A tibble with detailed profile information:
#' \describe{
#'   \item{handle}{Character. User's handle (e.g., "user.bsky.social")}
#'   \item{did}{Character. User's decentralized identifier}
#'   \item{displayName}{Character. User's display name}
#'   \item{description}{Character. User's bio/profile description}
#'   \item{avatar}{Character. URL to user's avatar image}
#'   \item{banner}{Character. URL to user's banner image}
#'   \item{followersCount}{Integer. Number of followers}
#'   \item{followsCount}{Integer. Number of accounts they follow}
#'   \item{postsCount}{Integer. Number of posts they've made}
#'   \item{createdAt}{Character. When the account was created}
#' }
#'   Returns \code{NULL} for users that don't exist or are inaccessible.
#'
#' @family api-wrappers
#' @seealso \code{\link{get_follows}}, \code{\link{get_followers}},
#'   \code{\link{get_user_posts}}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Get profile for a single user
#' profile <- get_profiles("neilhimself.neilgaiman.com", token)
#' print(profile)
#'
#' # Get profiles for multiple users efficiently
#' users <- c("user1.bsky.social", "user2.bsky.social", "user3.bsky.social")
#' profiles <- get_profiles(users, token)
#' head(profiles)
#'
#' # Use with network analysis
#' follows <- get_follows("example.bsky.social", token)
#' detailed_profiles <- get_profiles(follows$handle, token)
#'
#' # Filter by follower count
#' popular_users <- profiles[profiles$followersCount > 1000, ]
#' }
#'
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


#' Retrieve posts from a Bluesky user
#'
#' Fetches posts from a specific user's timeline on Bluesky Social with various
#' filtering options. Useful for content analysis, engagement tracking, and
#' understanding user posting patterns. Includes pagination support for large
#' post histories and robust error handling for reliable data collection.
#'
#' @param actor Character. User handle (e.g., "username.bsky.social") or DID
#'   of the user whose posts you want to retrieve
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param max_retries Integer. Number of times to retry on failure (default 3)
#' @param retry_delay Numeric. Delay in seconds between retries (default 5)
#' @param filter Character. Type of posts to retrieve (default "posts_no_replies"):
#' \describe{
#'   \item{posts_no_replies}{Original posts only, no replies}
#'   \item{posts_with_replies}{All posts including replies}
#'   \item{posts_with_media}{Posts containing images or videos}
#'   \item{posts_and_author_threads}{Posts and thread continuations}
#'   \item{posts_with_video}{Posts containing video content}
#' }
#' @param limit Integer. Maximum number of posts to retrieve (default 100)
#' @param return_df Logical. Return as tibble (TRUE) or raw JSON list (FALSE)
#'
#' @return If \code{return_df = TRUE}, a tibble with post information:
#' \describe{
#'   \item{actor}{Character. The user who made the post}
#'   \item{uri}{Character. Unique post identifier}
#'   \item{cid}{Character. Content identifier}
#'   \item{author_did}{Character. Author's DID}
#'   \item{author_handle}{Character. Author's handle}
#'   \item{author_displayName}{Character. Author's display name}
#'   \item{text}{Character. Post text content}
#'   \item{created_at}{Character. When the post was created}
#'   \item{reply_count}{Integer. Number of replies}
#'   \item{repost_count}{Integer. Number of reposts}
#'   \item{like_count}{Integer. Number of likes}
#'   \item{quote_count}{Integer. Number of quote posts}
#' }
#'   If \code{return_df = FALSE}, returns raw JSON response list.
#'
#' @family api-wrappers
#' @seealso \code{\link{get_profiles}}, \code{\link{word_freqs}}
#'
#' @section Endpoint documentation:
#' \href{https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/feed/getAuthorFeed.json}{Endpoint documentation}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Get recent posts from a user (no replies)
#' posts <- get_user_posts("neilhimself.neilgaiman.com", token, limit = 50)
#' head(posts[, c("text", "created_at", "like_count")])
#'
#' # Get posts with media content
#' media_posts <- get_user_posts("photographer.bsky.social", token,
#'                               filter = "posts_with_media", limit = 20)
#'
#' # Analyze posting patterns
#' user_posts <- get_user_posts("example.bsky.social", token, limit = 200)
#'
#' # Most engaging posts
#' top_posts <- user_posts[order(user_posts$like_count, decreasing = TRUE), ]
#' head(top_posts[, c("text", "like_count", "repost_count")], 10)
#'
#' # Text analysis of posts
#' post_words <- word_freqs(user_posts$text, top = 20)
#' head(post_words)
#'
#' # Get raw JSON for custom processing
#' raw_posts <- get_user_posts("example.bsky.social", token,
#'                             return_df = FALSE, limit = 10)
#' str(raw_posts[[1]]) # Examine structure
#' }
#'
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


#' Get complete follow records from user repository
#'
#' Retrieves all follow records from a user's personal repository on Bluesky.
#' This provides more detailed follow relationship data than \code{\link{get_follows}},
#' including record keys needed for \code{\link{unfollow_actor}} operations.
#' Useful for follow/unfollow management and relationship analysis.
#'
#' @param my_did Character. Your decentralized identifier (DID) from
#'   \code{\link{get_token}} response
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param max_retries Integer. Maximum number of retries on failure (default 3)
#' @param retry_delay Numeric. Delay in seconds between retries (default 5)
#'
#' @return A list of follow record objects, each containing:
#' \describe{
#'   \item{uri}{Character. Unique record identifier (contains rkey)}
#'   \item{cid}{Character. Content identifier}
#'   \item{value}{List. Record content with 'subject' (target DID) and metadata}
#' }
#'   Each record represents one follow relationship you've created.
#'
#' @family follow-management
#' @seealso \code{\link{unfollow_actor}}, \code{\link{find_follow_record}},
#'   \code{\link{extract_follow_subjects}}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' my_did <- auth$did
#'
#' # Get all your follow records
#' all_follows <- get_all_follow_records(my_did, token)
#' print(paste("You are following", length(all_follows), "users"))
#'
#' # Extract just the DIDs of people you follow
#' followed_dids <- extract_follow_subjects(all_follows)
#' head(followed_dids)
#'
#' # Find a specific follow record
#' target_profile <- get_profiles("example.bsky.social", token)
#' target_record <- find_follow_record(all_follows, target_profile$did)
#'
#' if (!is.null(target_record)) {
#'   # Unfollow using the record key
#'   rkey <- basename(target_record$uri)
#'   unfollow_actor(my_did, rkey, token)
#' }
#'
#' # Bulk unfollow inactive users (example workflow)
#' recent_active <- get_profiles(followed_dids[1:50], token)
#' old_follows <- recent_active[recent_active$postsCount < 5, ]
#'
#' for (did in old_follows$did) {
#'   record <- find_follow_record(all_follows, did)
#'   if (!is.null(record)) {
#'     rkey <- basename(record$uri)
#'     unfollow_actor(my_did, rkey, token)
#'     Sys.sleep(1) # Rate limiting
#'   }
#' }
#' }
#'
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
#' Extracts the DIDs (decentralized identifiers) of all users you are following
#' from the complete follow records retrieved by \\code{\\link{get_all_follow_records}}.
#' This is useful for getting a simple list of who you follow for analysis or
#' bulk operations without the full record metadata.
#'
#' @param follow_records List. Output from \\code{\\link{get_all_follow_records}}
#'   containing complete follow record objects
#'
#' @return Character vector of DIDs for all users you are following.
#'   Each DID is a unique identifier like "did:plc:abc123xyz..."
#'
#' @family follow-management
#' @seealso \\code{\\link{get_all_follow_records}}, \\code{\\link{find_follow_record}},
#'   \\code{\\link{get_profiles}}
#'
#' @examples
#' \\dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' my_did <- auth$did
#'
#' # Get all your follow records
#' all_follows <- get_all_follow_records(my_did, token)
#' print(paste("You have", length(all_follows), "follow records"))
#'
#' # Extract just the DIDs of people you follow
#' followed_dids <- extract_follow_subjects(all_follows)
#' print(paste("You are following", length(followed_dids), "unique users"))
#' head(followed_dids, 5)
#'
#' # Use DIDs to get detailed profile information
#' sample_profiles <- get_profiles(followed_dids[1:10], token)
#' print(sample_profiles[, c("displayName", "handle", "followersCount")])
#'
#' # Count follows by domain
#' handles_from_dids <- get_profiles(followed_dids, token)$handle
#' domains <- sapply(strsplit(handles_from_dids, "\\\\."), function(x) {
#'   if (length(x) >= 2) paste(tail(x, 2), collapse = ".") else x[1]
#' })
#' domain_counts <- sort(table(domains), decreasing = TRUE)
#' head(domain_counts, 10)
#'
#' # Find users you follow who follow each other (mutual connections)
#' mutual_matrix <- matrix(FALSE, length(followed_dids), length(followed_dids))
#' for (i in seq_along(followed_dids)) {
#'   user_follows <- get_follows(followed_dids[i], token)
#'   if (!is.null(user_follows)) {
#'     user_follow_dids <- get_profiles(user_follows$handle, token)$did
#'     mutual_matrix[i, ] <- followed_dids %in% user_follow_dids
#'   }
#'   Sys.sleep(1) # Rate limiting
#' }
#' }
#'
#' @export
extract_follow_subjects <- function(follow_records) {
  sapply(follow_records, function(record) record$value$subject)
}


#' Find follow record for specific actor
#'
#' Searches through your complete follow records to find the specific record
#' for a given user. This is essential for unfollow operations since you need
#' the record key (rkey) from the original follow record to delete it.
#'
#' @param follow_records List. Output from \\code{\\link{get_all_follow_records}}
#'   containing all your follow record objects
#' @param actor_did Character. The DID (decentralized identifier) of the user
#'   you want to find the follow record for
#'
#' @return The complete follow record object if found, \\code{NULL} if the user
#'   is not in your follows. The record contains:
#' \\describe{
#'   \\item{uri}{Character. Record URI containing the rkey needed for unfollowing}
#'   \\item{cid}{Character. Content identifier}
#'   \\item{value}{List. Record metadata including subject DID and creation time}
#' }
#'
#' @family follow-management
#' @seealso \\code{\\link{get_all_follow_records}}, \\code{\\link{unfollow_actor}},
#'   \\code{\\link{extract_follow_subjects}}
#'
#' @examples
#' \\dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' my_did <- auth$did
#'
#' # Get all your follow records
#' all_follows <- get_all_follow_records(my_did, token)
#'
#' # Find a specific user's profile to get their DID
#' target_profile <- get_profiles("example.bsky.social", token)
#' target_did <- target_profile$did
#'
#' # Find the follow record for that user
#' follow_record <- find_follow_record(all_follows, target_did)
#'
#' if (!is.null(follow_record)) {
#'   message("Found follow record for user!")
#'
#'   # Extract the rkey needed for unfollowing
#'   rkey <- basename(follow_record$uri)
#'   message("Record key: ", rkey)
#'
#'   # Unfollow the user
#'   result <- unfollow_actor(my_did, rkey, token)
#'   if (!is.null(result)) {
#'     message("Successfully unfollowed user!")
#'   }
#' } else {
#'   message("You are not following this user")
#' }
#'
#' # Batch processing: check if you follow multiple users
#' users_to_check <- c("user1.bsky.social", "user2.bsky.social", "user3.bsky.social")
#' check_profiles <- get_profiles(users_to_check, token)
#'
#' follow_status <- data.frame(
#'   handle = check_profiles$handle,
#'   following = sapply(check_profiles$did, function(did) {
#'     !is.null(find_follow_record(all_follows, did))
#'   })
#' )
#' print(follow_status)
#'
#' # Conditional unfollowing based on criteria
#' followed_dids <- extract_follow_subjects(all_follows)
#' followed_profiles <- get_profiles(followed_dids[1:50], token)  # Sample for demo
#'
#' # Unfollow users with very low activity (< 5 posts)
#' inactive_users <- followed_profiles[followed_profiles$postsCount < 5, ]
#'
#' for (did in inactive_users$did) {
#'   record <- find_follow_record(all_follows, did)
#'   if (!is.null(record)) {
#'     rkey <- basename(record$uri)
#'     unfollow_actor(my_did, rkey, token)
#'     message("Unfollowed inactive user: ", inactive_users$handle[inactive_users$did == did])
#'     Sys.sleep(1) # Rate limiting
#'   }
#' }
#' }
#'
#' @export
find_follow_record <- function(follow_records, actor_did) {
  for (record in follow_records) {
    if (record$value$subject == actor_did) {
      return(record)
    }
  }
  return(NULL)
}
