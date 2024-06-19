resp2df <- function(response, element) {
  # Pick one element out of an API response body, in JSON format
  # and turns it into a data frame, deselecting columns resulting
  # from lists

  df <- response |>
    purrr::pluck(element) |>
    purrr::map(unlist) |>
    purrr::map(t) |>
    purrr::map_dfr(dplyr::as_tibble) |>
    dplyr::select(-dplyr::starts_with(c("viewer", "labels")))

  return(df)
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
