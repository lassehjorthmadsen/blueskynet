# notes for create_net() to iteratively build a network
# Takes about a sec. per 100 handles to get profile info

library(devtools)
library(tidyverse)
library(cli)
library(progress)
load_all()

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

net <- readRDS("dev/net/bignet_2024-01-29.rds")

net_smp <- net |> slice_head(n = 100000)

# expnet$profiles |> saveRDS(file = "dev/net/profiles_2024-01-28.rds")

keywords <- read_csv(file = "dev/net/science_keywords.csv", col_names = F, col_types = "c")[[1]]

expnet <- expand_net(net_smp, keywords, token, refresh_tok, save_net = FALSE, threshold = 30, max_iterations = 100, sample_size = 4000)

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
  profiles <- tibble()
  i <- 1

  cat("Initial network:\n")
  cat("   Number of actors:", n_distinct(net$actor_handle), fill = T)
  cat("   Number of connections:", nrow(net), fill = T)

  while (i == 1 || nrow(all_follows) > 0 && i <= max_iterations) {

    cat("\nExpanding the network, iteration number:", i, fill = T)
    i <- i + 1
    start_time <- Sys.time()

    # Get handles for actors being followed (above threshold) by the current net
    new_handles <- net |>
      add_count(follows_handle) |>
      filter(!follows_handle %in% actor_handle, n >= threshold, follows_handle != "handle.invalid") |>
      slice_sample(n = sample_size) |>
      pull(follows_handle) |>
      unique()

    cat("   Number of actors meeting the followers threshold of ", threshold, ": ", length(new_handles), sep = "", fill = T)

    # Get profile information those handles, to check description for keywords
    new_profiles <- new_handles |> get_profiles(token)

    # Filter profiles
    if (nrow(profiles) > 0) {
    new_profiles <- new_profiles |>
      filter(handle != "invalid.handle") |>
      filter(str_detect(tolower(description), keywords))
    }

    cat("   Number of valid actors also matching the provided keywords: ", nrow(new_profiles), sep = "", fill = T)

    if (nrow(new_profiles) > 0) {

      final_handles <- new_profiles |> pull(handle)
      all_follows <- tibble()
      #prog_bar <- progress_bar$new(total = length(final_handles), clear = FALSE)
      cli_progress_bar(name = "   Getting follows", type = "iterator", clear = F, total = length(final_handles))


      for (n in seq(final_handles)) {
        #prog_bar$tick()

        follows <- get_follows(final_handles[n], token)

        if (nrow(follows) > 0) {
          follows <- follows |>
            mutate(actor_handle = final_handles[n]) |>
            select(actor_handle, follows_handle = handle)
          }

        all_follows <- bind_rows(all_follows, follows)

        # Refresh the token; unclear how often we need to do this, for now once per get_follows()
        refresh_object <- refresh_token(refresh_tok)
        token <- refresh_object$accessJwt
        refresh_tok <- refresh_object$refreshJwt

        cli_progress_update()
      }

      cat("   Number of new actors with followers to add to network: ", nrow(all_follows), sep = "", fill = T)

      profiles <- bind_rows(profiles, new_profiles)   # Store the profiles we have collected
      net <- bind_rows(net, all_follows)   # Append the new net to the existing; do another round
    }

    cat("\nUpdated network:", fill = T)
    cat("   Number of actors:", n_distinct(net$actor_handle), fill = T)
    cat("   Number of connections:", nrow(net), fill = T)
    cat("\n")
    print(Sys.time() - start_time)

    # Save the current net, overwriting earlier versions
    if (save_net) net |> saveRDS(file = file_name)

  }
  return(list("expanded_net" = net, "profiles" = profiles))
}
