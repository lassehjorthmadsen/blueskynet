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
                       file_name = paste0("dev/net/big_net_", Sys.Date(), ".rds"),
                       threshold = 30,
                       max_iterations = 50,
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

    if (floor(threshold) > 0) {
      prospects <- prospects |> dplyr::filter(.data$n >= threshold)
      } else {
      prospects <- prospects |> dplyr::filter(.data$frac >= threshold)
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

        if (nrow(follows) > 0) {
          follows <- follows |>
            dplyr::mutate(actor_handle = new_members[n]) |>
            dplyr::select(.data$actor_handle, follows_handle = .data$handle)
          }

        new_follows <- dplyr::bind_rows(new_follows, follows)

        cli::cli_progress_update()
      }

      cat("   Number of new actors with followers to add to network: ", nrow(new_follows), sep = "", fill = T)

      net <- dplyr::bind_rows(net, new_follows)   # Append the new net to the existing; do another round

      # Refresh the token; unclear how often we need to do this, for now once per iteration -- earlier: get_follows()
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
  return(net)
}


#' Trim network
#'
#' Iteratively trim a network so that the set of actors and the set of follows must be identical.
#' Also excludes rows with NA in either actors or follows columns. Finally, excludes
#' actors with less that 30 followers.
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

#' Create initial network
#'
#' Get all follows for a single actor, and use that to
#' form a minimal, initial network that can be expanded
#' later
#'
#' @param key_actor account identifier
#' @param keywords character vector with keywords that we check for in actors' description
#' @param token character, token for Blue Sky Social API
#' @return tibble with two columns, two columns: `actor_handle`
#' (the Blue Sky Social actor who is followING another) and `follows_handle`
#' (the actor being followed).
#' @export
#'
init_net <- function(key_actor, keywords, token) {

  keywords <- paste(keywords, collapse = "|")

  net <- key_actor  |>
    get_follows(token) |>
    dplyr::mutate(actor_handle = key_actor) |>
    dplyr::select(.data$actor_handle, follows_handle = .data$handle)

  profiles <- net$follows_handle |>
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

  #browser()
  metrics <- graph |>
    dplyr::as_tibble() |>
    dplyr::rename(handle = .data$name)

  if (!is.null(profiles)) {
    profiles <- profiles |>
      dplyr::left_join(metrics, by = "handle") |>
      dplyr::left_join(followers, by = c("handle" = "follows_handle"))
  }

  return(profiles)
}


#' Create a 3d-widget
#'
#' @param net tibble with two columns, two columns: `actor_handle`
#' (the Blue Sky Social actor who is followING another) and `follows_handle`
#' (the actor being followed).
#' @param profiles tibble with list of actors in net
#'
#' @return html widget
#' @importFrom igraph V
#' @importFrom tidygraph activate as_tbl_graph
#' @export
#'
create_widget <- function(net, profiles) {

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
#' @param key_actor account identifier
#' @param keywords character vector with keywords that we check for in actors' description
#' @param token character, token for Blue Sky Social API
#' @param refresh_tok character, refresh token for Blue Sky Social API
#' @param threshold the threshold for including actors in the expansion: How many
#' followers must a prospect have, to be considered? If smaller than 1, threshold is used
#' as a proportion: How big a proportion must a prospect have, to be considered?
#' @param ... Parameters passed on to `expand_net()`
#'
#' @return list of objects generated from `expand_net()`, `trim_net()`, `get_profiles()`,
#' `create_widget()`, and `word_freqs()`
#' @export
#'
build_network <- function(key_actor, keywords, token, refresh_tok, threshold, ...) {

  keywords <- keywords |> paste0(collapse = "|")

  # Get initial net based on key actor
  small_net <- init_net(key_actor, keywords, token)

  # Expand the net
  expnet <- expand_net(net = small_net,
                       keywords = keywords,
                       token = token,
                       refresh_tok = refresh_tok,
                       threshold = threshold,
                       ...)

  # Trim the net
  net <- expnet |> trim_net(threshold = threshold)

  # Get profiles
  profiles <- get_profiles(unique(net$actor_handle), token)

  # Add metrics
  profiles <- profiles |> add_metrics(net)

  # Word frequencies in descriptions
  freqs <- profiles$description |> word_freqs()

  # Create widget
  widget <- create_widget(net, profiles)

  return(list("net" = net, "profiles" = profiles, "widget" = widget, "freqs" = freqs))
}
