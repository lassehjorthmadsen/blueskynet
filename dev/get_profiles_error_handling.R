# Ideas for error tracking and handling from claude.ai


#' Get profile for an actor/actors
#'
#' @param actors character, actor handle
#' @param token character, api token
#' @param refresh_tok character, refresh token
#' @param chunksize integer, the number of actors per request;
#'     defaults to 25, currently the maximum number allowed
#' @param refresh_interval integer, number of chunks to process before refreshing token
#' @return tibble with profiles
#' @export
#'
get_profiles_error <- function(actors, token, refresh_tok, chunksize = 25, refresh_interval = 20) {
  actors_chunks <- split(actors, ceiling(seq_along(actors) / chunksize))
  actors_list <- actors_chunks |> purrr::map(~ purrr::set_names(as.list(.x), 'actors'))

  # Create progress bar
  pb <- progress::progress_bar$new(
    format = "   Getting profiles [:bar] :percent eta: :eta",
    total = length(actors_list),
    clear = FALSE,
    width = 60
  )

  req <- httr2::request('https://bsky.social/xrpc/app.bsky.actor.getProfiles') |>
    httr2::req_auth_bearer_token(token = token)

  resps <- purrr::map(seq_along(actors_list), function(i) {
    # Refresh token every refresh_interval chunks
    if (i %% refresh_interval == 0) {
      refresh_object <- refresh_token(refresh_tok)
      token <- refresh_object$accessJwt
      refresh_tok <- refresh_object$refreshJwt
      req <- httr2::request('https://bsky.social/xrpc/app.bsky.actor.getProfiles') |>
        httr2::req_auth_bearer_token(token = token)
    }

    tryCatch({
      resp <- httr2::req_url_query(req, !!!actors_list[[i]]) |>
        httr2::req_perform() |>
        check_wait() |>
        httr2::resp_body_json()
      pb$tick()
      resp
    }, error = function(e) {
      problematic_handles <- paste(actors_list[[i]]$actors, collapse = ", ")
      message(paste("Error occurred for handles:", problematic_handles))
      message(paste("Error message:", e$message))
      pb$tick()
      NULL
    })
  })

  df <- resps |>
    purrr::map_dfr(resp2df, element = "profiles")

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
get_profiles <- function(actors, token, chunksize = 25, max_retries = 3, retry_delay = 5) {
  actors_chunks <- split(actors, ceiling(seq_along(actors) / chunksize))
  actors_list <- actors_chunks |> purrr::map(~ purrr::set_names(as.list(.x), 'actors'))

  req <- httr2::request('https://bsky.social/xrpc/app.bsky.actor.getProfiles') |>
    httr2::req_auth_bearer_token(token = token)

  resps <- actors_list |>
    purrr::map(function(chunk) {
      for (attempt in 1:max_retries) {
        tryCatch({
          response <- httr2::req_url_query(req, actors = chunk$actors) |>
            httr2::req_perform()

          status <- httr2::resp_status(response)
          if (status == 200) {
            check_wait(response)
            return(httr2::resp_body_json(response))
          } else {
            message(paste("Request failed with status:", status, "for chunk:", paste(chunk$actors, collapse = ", ")))
            if (attempt < max_retries) {
              message(paste("Retrying in", retry_delay, "seconds..."))
              Sys.sleep(retry_delay)
            }
          }
        }, error = function(e) {
          message(paste("Error occurred:", e$message, "for chunk:", paste(chunk$actors, collapse = ", ")))
          if (attempt < max_retries) {
            message(paste("Retrying in", retry_delay, "seconds..."))
            Sys.sleep(retry_delay)
          }
        })
      }
      message(paste("Failed after", max_retries, "attempts for chunk:", paste(chunk$actors, collapse = ", ")))
      return(NULL)
    }, .progress = list(name = "   Getting profiles", clear = FALSE))

  df <- resps |> purrr::compact() |> purrr::map_dfr(resp2df, element = "profiles")

  return(df)
}
