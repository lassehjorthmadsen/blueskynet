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

    if (remaining == 0) {
      reset_time <- resp |>
        httr2::resp_header("RateLimit-Reset") |>
        as.numeric() |>
        as.POSIXct()

      wait_time <- reset_time - Sys.time() + as.difftime(1, 0, units = "secs")

      cat("Waiting for rate limit to reset:", fill = T)
      print(wait_time)
      Sys.sleep(wait_time)
    }

  }

  return(resp)
}
