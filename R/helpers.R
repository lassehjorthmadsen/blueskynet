resp2df <- function(response, element) {
  # Pick one element out of an API response body, in JSON format
  # and turns it into a data frame, deselecting columns resulting
  # from lists

  df <- response |>
    purrr::pluck(element) |>
    purrr::map(unlist) |>
    purrr::map(t) |>
    purrr::map(deselect_nested_cols) |>
    purrr::map_dfr(dplyr::as_tibble)

    return(df)
}


deselect_nested_cols <- function(mat) {
  # Find indices of columns without a period
  selected_indices <- which(!grepl("\\.", colnames(mat)))
  return(mat[, selected_indices, drop = FALSE])
}


post2df <- function(actor, response, element = "feed") {
  # Parse the response from 'getAuthorFeed' endpoint as documented
  # here: https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed
  # intended to be used by get_user_posts() wrapper function

  if (is.null(response)) return(NULL)

  df <- response |>
    purrr::pluck(element) |>
    purrr::map_dfr(function(item) {
      data.frame(
        # User identifier
        actor = actor,
        # Post identifiers
        uri = item$post$uri %||% NA_character_,
        cid = item$post$cid %||% NA_character_,

        # Author information
        author_did = item$post$author$did %||% NA_character_,
        author_handle = item$post$author$handle %||% NA_character_,
        author_displayName = item$post$author$displayName %||% NA_character_,

        # Post content
        text = item$post$record$text %||% NA_character_,
        created_at = item$post$record$createdAt %||% NA_character_,

        # Engagement metrics
        reply_count = item$post$replyCount %||% 0L,
        repost_count = item$post$repostCount %||% 0L,
        like_count = item$post$likeCount %||% 0L,
        quote_count = item$post$quoteCount %||% 0L,

        # Repost information
        is_repost = !is.null(item$reason),
        reposted_by = if (!is.null(item$reason))
          item$reason$by$handle
        else
          NA_character_,

        stringsAsFactors = FALSE      )
    })

  return(df)
}


check_wait <- function(resp) {
  # Only print rate limit info if we're getting close to the limit
  if (resp |> httr2::resp_header_exists("RateLimit-Remaining")) {
    remaining <- resp |> httr2::resp_header("RateLimit-Remaining") |> as.numeric()

    # Only show rate limit warning if we're running low
    if (remaining < 100) {  # Adjust threshold as needed
      limit <- resp |> httr2::resp_header("RateLimit-Limit")
      reset_time <- resp |>
        httr2::resp_header("RateLimit-Reset") |>
        as.numeric() |>
        as.POSIXct(origin = "1970-01-01")

      message("\n! Rate limit status: ", remaining, "/", limit)
      message("! Reset time: ", reset_time)
    }

    # Handle rate limit pause if needed
    if (remaining < 3) {
      reset_time <- resp |>
        httr2::resp_header("RateLimit-Reset") |>
        as.numeric() |>
        as.POSIXct()

      wait_time <- difftime(reset_time, Sys.time()) + as.difftime(1/60, units = "mins")
      message("\n! Waiting for rate limit reset at:", as.character(reset_time))
      units(wait_time) <- "secs"
      Sys.sleep(wait_time)
    }
  }

  return(resp)
}


#' Word frequencies
#'
#' @param texts character. Vector of texts (like profile descriptions)
#' @param bigrams boolean. Should we count bigrams? Default to FALSE
#' @param top integer. The top words/bi-grams to include. Defaults to 30
#' @param remove_stopwords boolean. Should stopwords be excluded? Defaults to TRUE
#' @param language character. The language to use when removing stopwords. Defaults to "en"
#'
#' @return dataframe with word (or bi-gram) frequencies
#' @export
#'
word_freqs <- function(texts, bigrams = FALSE, top = 30, remove_stopwords = TRUE, language = "en") {

  toks <- quanteda::corpus(texts) |>
    quanteda::tokens(remove_punct = TRUE) |>
    quanteda::tokens_remove(pattern = c(quanteda::stopwords(language), "|", "+"))

  if (bigrams) {
    toks <- toks |> quanteda::tokens_ngrams(n = 2, concatenator = " ")
    }

  freq <- quanteda::dfm(toks) |> quanteda.textstats::textstat_frequency(n = top)

  return(freq)
}
