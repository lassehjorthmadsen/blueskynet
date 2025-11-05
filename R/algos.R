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
#' @param threshold numeric, the threshold for including actors in the expansion: How many
#' followers must a prospect have, to be considered? If less then 1, interpreted as the *fraction*
#' of the current net prospects must be followed by, to be considered. Defaults to 30.
#' @param max_iterations integer, the maximum iterations in the network expansion. Defaults to 50
#' @param sample_size integer, if we want to expand only with a sample of the prospects;
#' can be useful for testing purposes. Defaults to `Inf´, e.g. every worthy prospect is included
#' in the expansion.
#'
#' @return list with a) a tibble with the expanded network: `actor_handle` contains all network member,
#' `follows_handle` contain all relevant actors that they follow (but not necessarily meeting
#' the `threshold`.) b) a new token, c) a new refresh token -- since the tokens might have beed
#' refreshed while underway
#'
#' @importFrom rlang .data
#' @importFrom cli cli_progress_bar cli_progress_update
#' @export
#'
expand_net <- function(net,
                       keywords,
                       token,
                       refresh_tok,
                       save_net = FALSE,
                       file_name,
                       threshold,
                       max_iterations,
                       sample_size = Inf) {

  keywords <- paste(keywords, collapse = "|")
  profiles <- dplyr::tibble()
  i <- 1

  cat("Initial network:\n")
  cat("   Number of actors     :", dplyr::n_distinct(net$actor_handle), fill = T)
  cat("   Number of follows    :", dplyr::n_distinct(net$follows_handle), fill = T)
  cat("   Number of connections:", nrow(net), fill = T)

  while (i == 1 || nrow(new_follows) > 0 && i <= max_iterations) {

    cat("\nExpanding the network, iteration number:", i, fill = T)
    i <- i + 1
    start_time <- Sys.time()

    # Get handles for actors being followed (above threshold) by the current net
    prospects <- net |>
      dplyr::add_count(.data$follows_handle) |>
      dplyr::mutate(frac = .data$n / dplyr::n_distinct(.data$actor_handle)) |>
      dplyr::filter(!.data$follows_handle %in% .data$actor_handle, .data$follows_handle != "handle.invalid") |>
      dplyr::slice_sample(n = sample_size)

    # You're included if you're above the threshold, OR at the maximum value
    if (floor(threshold) > 0) {
      prospects <- prospects |> dplyr::filter(.data$n >= threshold | .data$n == max(.data$n))
      } else {
      prospects <- prospects |> dplyr::filter(.data$frac >= threshold | .data$frac == max(.data$frac))
    }

    prospects <- prospects |>
      dplyr::pull(.data$follows_handle) |>
      unique()

    cat("   Number of prospects meeting the followers threshold of ", threshold, ": ", length(prospects), sep = "", fill = T)

    # Get profile information for new prospects, to check description for keywords
    if (nrow(profiles) == 0) {
      prospect_profiles <- prospects |> get_profiles(token)
      } else {
      prospect_profiles <- prospects |> setdiff(profiles$handle) |> get_profiles(token)
    }

    # Store the profiles we have collected, to avoid having to collect again
    profiles <- dplyr::bind_rows(profiles, prospect_profiles)

    # Get back profile information for all prospects
    prospect_profiles <- profiles |>
      dplyr::filter(.data$handle %in% prospects)

    # Filter profiles
    if (nrow(prospect_profiles) > 0) {
      prospect_profiles <- prospect_profiles |>
      dplyr::filter(.data$handle != "invalid.handle") |>
      dplyr::filter(stringr::str_detect(tolower(.data$description), keywords))
    }

    cat("   Number of valid prospects also matching the provided keywords: ", nrow(prospect_profiles), sep = "", fill = T)

    new_follows <- dplyr::tibble()

    if (nrow(prospect_profiles) > 0) {

      new_members <- prospect_profiles |> dplyr::pull(.data$handle)
      cli::cli_progress_bar(name = "   Getting follows ", type = "iterator", clear = F, total = length(new_members))

      for (n in seq(new_members)) {

        follows <- get_follows(new_members[n], token)
        if (!is.data.frame(follows)) follows <- NULL

        if (!is.null(follows) && nrow(follows) > 0) {
          follows <- follows |>
            dplyr::mutate(actor_handle = new_members[n]) |>
            dplyr::select(.data$actor_handle, follows_handle = .data$handle)
          }

        new_follows <- dplyr::bind_rows(new_follows, follows)

        cli::cli_progress_update()
      }

      cat("   Number of new actors with followers to add to network: ", dplyr::n_distinct(new_follows$actor_handle), sep = "", fill = T)

      net <- dplyr::bind_rows(net, new_follows)   # Append the new net to the existing; do another round

      # Refresh the token; unclear how often we need to do this, for now once per iteration
      # Earlier: once per get_follows() call
      refresh_object <- refresh_token(refresh_tok)
      token <- refresh_object$accessJwt
      refresh_tok <- refresh_object$refreshJwt
    }

    cat("\nUpdated network:", fill = T)
    cat("   Number of actors     :", dplyr::n_distinct(net$actor_handle), fill = T)
    cat("   Number of follows    :", dplyr::n_distinct(net$follows_handle), fill = T)
    cat("   Number of connections:", nrow(net), fill = T)
    cat("\n")
    print(Sys.time() - start_time)

    # Save the current net, overwriting earlier versions
    if (save_net) net |> saveRDS(file = file_name)

  }
  # Return the expanded net and the new tokens we have obtained underway
  return(list("net" = net, "token" = token, "refresh_tok" = refresh_tok))
}


#' Trim network
#'
#' Iteratively trims a network so that the set of actors and the set of follows are identical.
#' Also excludes rows with NA in either actors or follows columns or invalid handle. Finally,
#' excludes actors with less that a certain number of followers within the network.
#'
#' @param net tibble with network connections (edges). Assumed to contain two columns:
#' `actor_handle` (the Blue Sky Social actor who is followING another) and `follows_handle`
#' (the actor being followed).
#' @param threshold the threshold for including actors in the expansion: How many
#' followers must a prospect have, to be considered? If smaller than 1, threshold is used
#' as a proportion: How big a proportion must a prospect have, to be considered?
#'
#' @return tibble with the expanded network
#' @importFrom rlang .data
#' @export
#'
trim_net <- function(net, threshold) {

  net <- net |>
    dplyr::distinct(.keep_all = TRUE) |>
    dplyr::filter(.data$follows_handle != "handle.invalid") |>
    stats::na.omit()

  i <- 0
  while (i == 0 || !dplyr::setequal(net$follows_handle, net$actor_handle)) {
    i <- i + 1

    net <- net |>
      dplyr::add_count(.data$follows_handle) |>
      dplyr::mutate(frac = .data$n / dplyr::n_distinct(.data$actor_handle))

    if (floor(threshold) > 0) {
      net <- net |> dplyr::filter(.data$n >= threshold)
    } else {
      net <- net |> dplyr::filter(.data$frac >= threshold)
    }

    net <- net |>
      dplyr::filter(.data$follows_handle %in% .data$actor_handle,
                    .data$actor_handle %in% .data$follows_handle) |>
      dplyr::select(-.data$n, -.data$frac)
  }

  return(net)
}

#' Initialize a network from key actors
#'
#' Creates an initial network by getting all the accounts that key actors follow,
#' then filtering those accounts based on profile keywords. This forms the seed
#' network that can later be expanded using \code{\link{expand_net}}.
#'
#' @param key_actors Character vector. Handles (e.g., "username.bsky.social") of
#'   the central actors whose follows will form the initial network
#' @param keywords Character vector. Keywords to search for in user profile
#'   descriptions to determine if they should be included in the network
#' @param token Character. Authentication token from \code{\link{get_token}}
#'
#' @return A tibble with network edges (follow relationships):
#' \describe{
#'   \item{actor_handle}{Character. Handle of the user doing the following}
#'   \item{follows_handle}{Character. Handle of the user being followed}
#' }
#'   This represents the initial network structure where each row is a
#'   follow relationship between two users.
#'
#' @family network-building
#' @seealso \code{\link{expand_net}}, \code{\link{build_network}},
#'   \code{\link{get_follows}}
#'
#' @examples
#' \dontrun{
#' # Authenticate first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#'
#' # Create initial network from science communicators
#' key_scientists <- c("neilhimself.neilgaiman.com", "example.scientist.bsky.social")
#' science_keywords <- c("scientist", "researcher", "academic", "PhD")
#'
#' initial_net <- init_net(key_scientists, science_keywords, token)
#' print(paste("Initial network has", nrow(initial_net), "connections"))
#'
#' # Create network for journalists
#' journalists <- c("reporter.bsky.social", "news.bsky.social")
#' media_keywords <- c("journalist", "reporter", "news", "media")
#' media_net <- init_net(journalists, media_keywords, token)
#'
#' # Examine the network structure
#' unique_actors <- length(unique(c(initial_net$actor_handle, initial_net$follows_handle)))
#' print(paste("Network contains", unique_actors, "unique users"))
#' }
#'
#' @export
#'
init_net <- function(key_actors, keywords, token) {

  keywords <- paste(keywords, collapse = "|")

  net <- key_actors |>
    purrr::map(get_follows, token) |>
    purrr::set_names(key_actors) |>
    dplyr::bind_rows(.id = "actor_handle") |>
    dplyr::select(.data$actor_handle, follows_handle = .data$handle)

  # Unsure exactly why "handle.invalid" happens, but it can't be useful, so get rid of it
  net <- net |> dplyr::filter(.data$follows_handle != "handle.invalid")

  profiles <- net$follows_handle |>
    unique() |>
    get_profiles(token)

  profiles |>
    dplyr::filter(stringr::str_detect(tolower(.data$description), keywords))

  if (nrow(profiles) == 0) stop("Failed to initialize net; no follows that matches keywords")

  net <- net |>
    dplyr::filter(.data$follows_handle %in% profiles$handle)

  return(net)
}


#' Add selected network metrics to actors
#'
#' @param profiles tibble with list of actors in net
#' @param net tibble with two columns, two columns: `actor_handle`
#' (the Blue Sky Social actor who is followING another) and `follows_handle`
#' (the actor being followed).
#'
#' @return tibble with profiles and extra columns for metrics
#' @export
#'
add_metrics <- function(profiles, net) {

  # Compute centrality metrics
  # 1. graph object
  graph <- net |> tidygraph::as_tbl_graph()

  # 2. compute centrality
  centrality <- igraph::centr_betw(graph)
  igraph::V(graph)$centrality <- centrality$res

  # 3. Identify high density subgraphs, "communities"
  community <- igraph::cluster_walktrap(graph)
  igraph::V(graph)$community <- community$membership

  # 4. compute page rank
  prank <- igraph::page.rank(graph)
  igraph::V(graph)$pageRank <- prank$vector

  # 5. Join profiles with metrics
  followers <- net |>
    dplyr::count(.data$follows_handle, name = "insideFollowers")

  metrics <- graph |>
    dplyr::as_tibble() |>
    dplyr::rename(handle = .data$name)

  if (!is.null(profiles)) {

    profiles <- profiles |>
      dplyr::left_join(metrics, by = "handle") |>
      dplyr::left_join(followers, by = c("handle" = "follows_handle"))

    profiles <- profiles |>
      dplyr::left_join(com_labels(profiles), by = "community")
  }

  return(profiles)
}


#' Create a 3d-widget
#'
#' @param net tibble with two columns, two columns: `actor_handle`
#' (the Blue Sky actor who is followING another) and `follows_handle`
#' (the actor being followed).
#' @param profiles tibble with list of actors in net
#' @param prop proportion of the actors sampled for visualization
#'
#' @return html widget
#' @importFrom igraph V
#' @importFrom tidygraph activate as_tbl_graph
#' @export
#'
create_widget <- function(net, profiles, prop = 1) {

  if (prop < 1) {
    profiles <- profiles |> dplyr::slice_sample(prop = prop)
    net <- net |> dplyr::filter(.data$actor_handle %in% profiles$handle, .data$follows_handle %in% profiles$handle)
  }

  # Create graph object
  graph <- net |> tidygraph::as_tbl_graph()

  # Identify high density subgraphs, "communities"
  community <- igraph::cluster_walktrap(graph)
  igraph::V(graph)$community <- community$membership

  # Edges and nodes as tibbles
  edges <- graph |>
    tidygraph::activate(edges) |>
    dplyr::as_tibble()

  nodes <- graph |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(id = dplyr::row_number()) |> dplyr::as_tibble()

  # Make labels for nodes
  nodes <- nodes |>
    dplyr::mutate(com_label = forcats::fct_infreq(as.character(community)),
                  com_label = forcats::fct_lump(.data$com_label, n = 10)) |>
    dplyr::group_by(.data$com_label) |>
    dplyr::mutate(n = dplyr::n(),
                  com_id = dplyr::cur_group_id()) |>
    dplyr::ungroup() |>
    dplyr::mutate(com_label = ifelse(.data$com_id == max(.data$com_id), "Other",
                              paste0(LETTERS[.data$com_id], ", n=", .data$n))) |>
    dplyr::left_join(profiles, by = c("name" = "handle"))

  # Make colors based on communities
  community_cols <- 3 |>
    RColorBrewer::brewer.pal("Set1") |>
    grDevices::colorRampPalette()

  use_colors <- dplyr::n_distinct(nodes$com_label) |>
    community_cols() |>
    sample()

  nodes <- nodes |>
    dplyr::mutate(color = use_colors[.data$com_id], groupname = .data$com_label)

  # 3d plot with threejs
  widget <- threejs::graphjs(graph, bg = "black",
                             vertex.size = 0.2,
                             edge.width = .3,
                             edge.alpha = .3,
                             vertex.color = nodes$color,
                             vertex.label = paste(nodes$displayName, nodes$description, sep = ": "))

    return(widget)
}

#' Build a complete network and helpful artifacts
#'
#' @param key_actors character vector with account identifiers
#' @param keywords character vector with keywords that we check for in actors' description
#' @param token character, token for Blue Sky Social API
#' @param refresh_tok character, refresh token for Blue Sky Social API
#' @param threshold the threshold for including actors in the expansion: How many
#' followers must a prospect have, to be considered? If smaller than 1, threshold is used
#' as a proportion: How big a proportion must a prospect have, to be considered?
#' @param prop proportion of the actors sampled for visualization, passed on to `create_widget()`
#' @param ... Parameters passed on to `expand_net()`
#'
#' @return list of objects generated from `expand_net()`, `trim_net()`, `get_profiles()`,
#' `create_widget()`, and `word_freqs()`
#' @export
#'
build_network <- function(key_actors, keywords, token, refresh_tok, threshold, prop, ...) {

  keywords <- keywords |> paste0(collapse = "|")

  # Get initial net based on key actor
  small_net <- init_net(key_actors, keywords, token)

  # Expand the net
  expnet <- expand_net(net = small_net,
                       keywords = keywords,
                       token = token,
                       refresh_tok = refresh_tok,
                       threshold = threshold,
                       ...)

  # Get the expanded network and token (it might have been refreshed)
  token <- expnet$token
  expnet <- expnet$net

  # Trim the net
  net <- expnet |> trim_net(threshold = threshold)

  # Get profiles
  profiles <- get_profiles(unique(net$actor_handle), token)

  # Add metrics
  profiles <- profiles |> add_metrics(net)

  # Word frequencies in descriptions
  freqs <- profiles$description |> word_freqs()

  # Create widget
  widget <- create_widget(net, profiles, prop)

  return(list("net" = net, "profiles" = profiles, "widget" = widget, "freqs" = freqs))
}


# Get the top 3 words (tf-idf-weighted) per community, use as labels


#' Generate labels for network communities
#'
#' Creates descriptive labels for network communities by analyzing the most
#' frequent words (using TF-IDF weighting) in user profile descriptions within
#' each community.
#'
#' @param profiles Data frame or tibble with profile information, must contain:
#' \describe{
#'   \item{community}{Integer. Community assignment for each user}
#'   \item{description}{Character. User profile descriptions/bios to analyze}
#' }
#' @param top Integer. Number of top words to include in each label (default 3)
#'
#' @return A tibble with community labels:
#' \describe{
#'   \item{community}{Integer. Community ID}
#'   \item{community_label}{Character. Descriptive label with top keywords}
#' }
#'
#' @family network-analysis
#' @seealso \code{\link{add_metrics}}, \code{\link{word_freqs}}
#'
#' @examples
#' \dontrun{
#' # Create sample profile data
#' sample_profiles <- data.frame(
#'   community = c(1, 1, 1, 2, 2, 2),
#'   description = c(
#'     "Data scientist working on machine learning projects",
#'     "Machine learning researcher at university",
#'     "AI and data science consultant",
#'     "Climate change researcher studying ocean temperatures",
#'     "Environmental scientist focusing on climate data",
#'     "Oceanographer studying climate impacts"
#'   )
#' )
#'
#' # Generate community labels
#' labels <- com_labels(sample_profiles, top = 2)
#' print(labels)
#' }
#'
#' \dontrun{
#' # With real network data
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' net <- build_network("example.bsky.social", c("science", "research"),
#'                      auth$accessJwt, auth$refreshJwt, threshold = 30, prop = 0.1)
#' labels <- com_labels(net$profiles, top = 3)
#' }
#'
#' @export
#'
com_labels <- function(profiles, top = 3) {
  corpus_obj <- quanteda::corpus(profiles, text_field = "description")
  quanteda::docvars(corpus_obj, "community") <- profiles$community

  df <-
    corpus_obj |>
    quanteda::tokens(remove_punct = TRUE) |>
    quanteda::tokens_remove(pattern = c(quanteda::stopwords("en"), "|")) |>
    quanteda::dfm() |>
    quanteda::dfm_tfidf() |>
    quanteda::topfeatures(n = top, groups = community) |>
    purrr::map(names) |>
    purrr::map_chr(paste, collapse = " | ") |>
    dplyr::as_tibble() |>
    dplyr::mutate(community = dplyr::row_number()) |>
    dplyr::rename(community_label = .data$value)

  return(df)
}
