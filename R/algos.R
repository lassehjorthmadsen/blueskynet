#' Expand network
#'
#' @param net tibble with network connections (edges). Assumed to contain two columns:
#' `actor_handle` (the Blue Sky Social actor who is followING another) and `follows_handle`
#' (the actor being followed).
#' @param keywords character vector with keywords that we check for in actors' description
#' to determine if they belong in the expanded network
#' @param token character, token for Blue Sky Social API
#' @param refresh_tok character, refresh token for Blue Sky Social API
#' @param save_net boolean, should the net be saved incrementally as it is expanded? Useful
#' for not losing work in case of unexpected interruptions. Defaults to `FALSE`
#' @param file_name character, file name of the saved net. Defaults to 'dev/net/bignet_TIMESTAMP.rds'
#' @param threshold integer, the threshold for including actors in the expansion: How many
#' followers must a prospect have, to be considered? Defaults to 30.#'
#' @param max_iterations integer, the maximum iterations in the network expansion. Defaults to 50
#' @param sample_size integer, if we want to expand only with a sample of the prospects;
#' can be useful for testing purposes. Defaults to `Inf´, e.g. every worthy prospect is included
#' in the expansion
#'
#' @return tibble with the expanded network
#' @importFrom rlang .data
#' @export
#'
expand_net <- function(net,
                       keywords,
                       token,
                       refresh_tok,
                       save_net = FALSE,
                       file_name = paste0("dev/net/bignet_", Sys.Date(), ".rds"),
                       threshold = 30,
                       max_iterations = 50,
                       sample_size = Inf) {

  keywords <- paste(keywords, collapse = "|")
  profiles <- dplyr::tibble()
  i <- 1

  cat("Initial network:\n")
  cat("   Number of actors:", dplyr::n_distinct(net$actor_handle), fill = T)
  cat("   Number of connections:", nrow(net), fill = T)

  while (i == 1 || nrow(all_follows) > 0 && i <= max_iterations) {

    cat("\nExpanding the network, iteration number:", i, fill = T)
    i <- i + 1
    start_time <- Sys.time()

    # Get handles for actors being followed (above threshold) by the current net
    new_handles <- net |>
      dplyr::add_count(.data$follows_handle) |>
      dplyr::filter(!.data$follows_handle %in% .data$actor_handle, n >= threshold, .data$follows_handle != "handle.invalid") |>
      dplyr::slice_sample(n = sample_size) |>
      dplyr::pull(.data$follows_handle) |>
      unique()

    cat("   Number of actors meeting the followers threshold of ", threshold, ": ", length(new_handles), sep = "", fill = T)

    # Get profile information those handles, to check description for keywords
    new_profiles <- new_handles |> get_profiles(token)

    # Filter profiles
    if (nrow(new_profiles) > 0) {
    new_profiles <- new_profiles |>
      dplyr::filter(.data$handle != "invalid.handle") |>
      dplyr::filter(stringr::str_detect(tolower(.data$description), keywords))
    }

    cat("   Number of valid actors also matching the provided keywords: ", nrow(new_profiles), sep = "", fill = T)

    if (nrow(new_profiles) > 0) {

      final_handles <- new_profiles |> dplyr::pull(.data$handle)
      all_follows <- dplyr::tibble()
      #prog_bar <- progress_bar$new(total = length(final_handles), clear = FALSE)
      cli::cli_progress_bar(name = "   Getting follows ", type = "iterator", clear = F, total = length(final_handles))


      for (n in seq(final_handles)) {
        #prog_bar$tick()

        follows <- get_follows(final_handles[n], token)

        if (nrow(follows) > 0) {
          follows <- follows |>
            dplyr::mutate(actor_handle = final_handles[n]) |>
            dplyr::select(.data$actor_handle, follows_handle = .data$handle)
          }

        all_follows <- dplyr::bind_rows(all_follows, follows)

        # Refresh the token; unclear how often we need to do this, for now once per get_follows()
        refresh_object <- refresh_token(refresh_tok)
        token <- refresh_object$accessJwt
        refresh_tok <- refresh_object$refreshJwt

        cli::cli_progress_update()
      }

      cat("   Number of new actors with followers to add to network: ", dplyr::n_distinct(all_follows$actor_handle), sep = "", fill = T)

      profiles <- dplyr::bind_rows(profiles, new_profiles)   # Store the profiles we have collected
      net <- dplyr::bind_rows(net, all_follows)   # Append the new net to the existing; do another round
    }

    cat("\nUpdated network:", fill = T)
    cat("   Number of actors:", dplyr::n_distinct(net$actor_handle), fill = T)
    cat("   Number of connections:", nrow(net), fill = T)
    cat("\n")
    print(Sys.time() - start_time)

    # Save the current net, overwriting earlier versions
    if (save_net) net |> saveRDS(file = file_name)

  }
  return(list("expanded_net" = net, "profiles" = profiles))
}
