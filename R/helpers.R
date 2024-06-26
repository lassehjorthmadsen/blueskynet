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


check_wait <- function(resp) {
  # Check response headers, if rate limit reached, wait until reset

  if (resp |> httr2::resp_header_exists("RateLimit-Remaining")) {

    remaining <- resp |> httr2::resp_header("RateLimit-Remaining") |> as.numeric()

    if (remaining < 3) { # It looks like a follow post request uses up 3 RateLimits?
      reset_time <- resp |>
        httr2::resp_header("RateLimit-Reset") |>
        as.numeric() |>
        as.POSIXct()

      wait_time <- difftime(reset_time, Sys.time()) + as.difftime(1/60, units = "mins")

      cat("Waiting for rate limit to reset at:", as.character(reset_time), fill = T)
      print(wait_time)

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
