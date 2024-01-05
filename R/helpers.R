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
