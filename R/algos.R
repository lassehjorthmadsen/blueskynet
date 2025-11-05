#' Expand network through iterative growth
#'
#' Expands an initial network by iteratively finding new users who are followed
#' by many existing network members and match specified keywords. This is the core
#' algorithm for growing networks from a seed set of users.
#'
#' @param net Tibble. Initial network with follow relationships, must contain:
#' \describe{
#'   \item{actor_handle}{Character. User who is following}
#'   \item{follows_handle}{Character. User being followed}
#' }
#' @param keywords Character vector. Keywords to search for in user profile
#'   descriptions to determine network membership eligibility
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param refresh_tok Character. Refresh token from \code{\link{get_token}} for
#'   long-running operations
#' @param save_net Logical. Should the network be saved incrementally during expansion
#'   to prevent data loss? (default FALSE)
#' @param file_name Character. File path for incremental saves. If not provided,
#'   defaults to 'dev/net/bignet_TIMESTAMP.rds'
#' @param threshold Numeric. Inclusion threshold for new users:
#' \describe{
#'   \item{>= 1}{Minimum number of existing network members who must follow a prospect}
#'   \item{< 1}{Fraction of network members who must follow a prospect}
#' }
#' @param max_iterations Integer. Maximum number of expansion iterations (default 50)
#' @param sample_size Integer. Maximum prospects to consider per iteration.
#'   Use \code{Inf} for no limit (default), smaller values for testing
#'
#' @return A list containing the expanded network results:
#' \describe{
#'   \item{net}{Tibble. Expanded network with all follow relationships discovered}
#'   \item{token}{Character. Updated access token (may have been refreshed)}
#'   \item{refresh_tok}{Character. Updated refresh token}
#'   \item{profiles}{Tibble. Profile information for all network members}
#'   \item{iterations}{Integer. Number of iterations completed}
#' }
#'
#' @family network-building
#' @seealso \code{\link{init_net}}, \code{\link{build_network}},
#'   \code{\link{trim_net}}
#'
#' @examples
#' \dontrun{
#' # Start with an initial network
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' token <- auth$accessJwt
#' refresh_tok <- auth$refreshJwt
#'
#' # Create initial network
#' initial <- init_net("example.scientist.bsky.social",
#'                     c("research", "science"), token)
#'
#' # Expand the network - conservative approach
#' expanded <- expand_net(
#'   net = initial,
#'   keywords = c("research", "science", "academic", "PhD"),
#'   token = token,
#'   refresh_tok = refresh_tok,
#'   threshold = 5,        # Need 5+ followers from existing network
#'   max_iterations = 10,  # Limit iterations for testing
#'   save_net = TRUE       # Save progress incrementally
#' )
#'
#' print(paste("Network grew from", nrow(initial), "to",
#'             nrow(expanded$net), "connections"))
#'
#' # More aggressive expansion with lower threshold
#' large_expansion <- expand_net(
#'   net = expanded$net,
#'   keywords = c("research", "science", "academic"),
#'   token = expanded$token,
#'   refresh_tok = expanded$refresh_tok,
#'   threshold = 0.1,      # 10% of network must follow prospect
#'   max_iterations = 25
#' )
#' }
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


#' Clean and trim network to create cohesive community
#'
#' Iteratively refines a network by removing isolated users and applying follower
#' thresholds to create a cohesive community where every user both follows and
#' is followed by others within the network. This produces cleaner network
#' visualizations and more meaningful community analysis.
#'
#' @param net Tibble. Network edge list with follow relationships containing:
#' \\describe{
#'   \\item{actor_handle}{Character. User who is following another}
#'   \\item{follows_handle}{Character. User being followed}
#' }
#' @param threshold Numeric. Inclusion threshold for users:
#' \\describe{
#'   \\item{>= 1}{Minimum number of followers within the network required}
#'   \\item{< 1}{Minimum proportion of network that must follow the user}
#' }
#'
#' @return Tibble. Cleaned network with the same structure as input but with:
#' \\itemize{
#'   \\item{All duplicate edges removed}
#'   \\item{Invalid handles and NA values excluded}
#'   \\item{Users below follower threshold removed}
#'   \\item{Only users who both follow and are followed within the network}
#' }
#'   The resulting network forms a more cohesive community for analysis.
#'
#' @details
#' The trimming process works iteratively:
#' \\enumerate{
#'   \\item{Remove duplicate connections and invalid/missing handles}
#'   \\item{Count followers for each user within the network}
#'   \\item{Remove users below the specified threshold}
#'   \\item{Keep only users who appear as both followers and followed}
#'   \\item{Repeat until the network stabilizes}
#' }
#'
#' This creates a "core community" where every member has meaningful
#' connections within the group, improving visualization quality and
#' analytical insights.
#'
#' @family network-building
#' @seealso \\code{\\link{expand_net}}, \\code{\\link{build_network}},
#'   \\code{\\link{add_metrics}}
#'
#' @examples
#' \\dontrun{
#' # Build an initial network
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' initial_net <- init_net(
#'   c("scientist1.bsky.social", "researcher2.bsky.social"),
#'   c("science", "research"),
#'   auth$accessJwt
#' )
#'
#' # Expand the network
#' expanded <- expand_net(
#'   net = initial_net,
#'   keywords = c("science", "research", "academic"),
#'   token = auth$accessJwt,
#'   refresh_tok = auth$refreshJwt,
#'   threshold = 5,
#'   max_iterations = 10
#' )
#'
#' # Before trimming - show network size
#' cat("Before trimming:")
#' cat("  Unique actors:", length(unique(expanded$net$actor_handle)))
#' cat("  Unique follows:", length(unique(expanded$net$follows_handle)))
#' cat("  Total connections:", nrow(expanded$net))
#'
#' # Trim to create cohesive community (need 10+ internal followers)
#' trimmed_net <- trim_net(expanded$net, threshold = 10)
#'
#' # After trimming - show the refined network
#' cat("After trimming:")
#' cat("  Unique users:", length(unique(trimmed_net$actor_handle)))
#' cat("  Total connections:", nrow(trimmed_net))
#'
#' # Verify all users both follow and are followed
#' actors <- unique(trimmed_net$actor_handle)
#' follows <- unique(trimmed_net$follows_handle)
#' cat("Network cohesion check:")
#' cat("  All actors also appear as follows:", all(actors %in% follows))
#' cat("  All follows also appear as actors:", all(follows %in% actors))
#'
#' # Compare network density before and after
#' users_before <- length(unique(c(expanded$net$actor_handle, expanded$net$follows_handle)))
#' users_after <- length(unique(c(trimmed_net$actor_handle, trimmed_net$follows_handle)))
#' density_before <- nrow(expanded$net) / (users_before * (users_before - 1))
#' density_after <- nrow(trimmed_net) / (users_after * (users_after - 1))
#'
#' cat("Network density improved from", round(density_before, 4), "to", round(density_after, 4))
#'
#' # Use proportional threshold for smaller networks
#' # Require at least 20% of network to follow each user
#' proportional_trim <- trim_net(initial_net, threshold = 0.2)
#' }
#'
#' @importFrom rlang .data
#' @export
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


#' Add network analysis metrics to user profiles
#'
#' Computes and adds comprehensive network analysis metrics to user profile data.
#' This function calculates centrality measures, community detection, and PageRank
#' scores to identify influential users and network structure within your Bluesky
#' social network.
#'
#' @param profiles Tibble. User profile information from \\code{\\link{get_profiles}}
#'   containing at least handle and other profile details
#' @param net Tibble. Network edge list with follow relationships containing:
#' \\describe{
#'   \\item{actor_handle}{Character. User who is following another}
#'   \\item{follows_handle}{Character. User being followed}
#' }
#'
#' @return Tibble with original profile data enhanced with network metrics:
#' \\describe{
#'   \\item{centrality}{Numeric. Betweenness centrality score (influence as bridge)}
#'   \\item{community}{Integer. Community assignment from cluster analysis}
#'   \\item{pageRank}{Numeric. PageRank score (influence based on follower quality)}
#'   \\item{insideFollowers}{Integer. Number of followers within this network}
#'   \\item{community_label}{Character. Descriptive label for the community}
#' }
#'   Plus all original profile columns (handle, displayName, description, etc.)
#'
#' @details
#' The function performs several network analysis computations:
#' \\itemize{
#'   \\item{Betweenness centrality: Identifies users who act as bridges between communities}
#'   \\item{Community detection: Uses random walks to find densely connected groups}
#'   \\item{PageRank: Measures influence based on follower network quality}
#'   \\item{Inside followers: Counts followers within the analyzed network subset}
#'   \\item{Community labels: Generates descriptive labels using TF-IDF of user bios}
#' }
#'
#' @family network-analysis
#' @seealso \\code{\\link{build_network}}, \\code{\\link{com_labels}},
#'   \\code{\\link{create_widget}}
#'
#' @examples
#' \\dontrun{
#' # Build a network first
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' network_result <- build_network(
#'   key_actors = c("scientist.bsky.social", "researcher.bsky.social"),
#'   keywords = c("science", "research", "academic"),
#'   token = auth$accessJwt,
#'   refresh_tok = auth$refreshJwt,
#'   threshold = 10
#' )
#'
#' # Add comprehensive metrics to profiles
#' enhanced_profiles <- add_metrics(network_result$profiles, network_result$net)
#'
#' # Examine the most central (influential) users
#' top_central <- enhanced_profiles[
#'   order(enhanced_profiles$centrality, decreasing = TRUE),
#' ][1:10, c("displayName", "handle", "centrality", "pageRank")]
#' print(top_central)
#'
#' # Find the most influential users by PageRank
#' top_pagerank <- enhanced_profiles[
#'   order(enhanced_profiles$pageRank, decreasing = TRUE),
#' ][1:10, c("displayName", "handle", "pageRank", "followersCount")]
#' print(top_pagerank)
#'
#' # Analyze community structure
#' community_summary <- enhanced_profiles |>
#'   group_by(community, community_label) |>
#'   summarise(
#'     members = n(),
#'     avg_followers = mean(followersCount, na.rm = TRUE),
#'     avg_centrality = mean(centrality, na.rm = TRUE),
#'     .groups = "drop"
#'   ) |>
#'   arrange(desc(members))
#' print(community_summary)
#'
#' # Find users who bridge communities (high centrality)
#' bridge_users <- enhanced_profiles[
#'   enhanced_profiles$centrality > quantile(enhanced_profiles$centrality, 0.9, na.rm = TRUE),
#'   c("displayName", "handle", "centrality", "community_label")
#' ]
#' print(bridge_users)
#'
#' # Compare internal vs external influence
#' influence_comparison <- enhanced_profiles |>
#'   select(handle, followersCount, insideFollowers, pageRank) |>
#'   mutate(
#'     external_followers = followersCount - insideFollowers,
#'     influence_ratio = insideFollowers / followersCount
#'   ) |>
#'   arrange(desc(influence_ratio))
#' head(influence_comparison, 10)
#' }
#'
#' @export
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


#' Create interactive 3D network visualization widget
#'
#' Creates an interactive 3D visualization of your Bluesky social network using
#' WebGL. The visualization shows users as nodes colored by community membership
#' and connections as edges, allowing you to explore network structure, identify
#' clusters, and understand relationship patterns in your social network.
#'
#' @param net Tibble. Network edge list with follow relationships containing:
#' \\describe{
#'   \\item{actor_handle}{Character. User who is following another}
#'   \\item{follows_handle}{Character. User being followed}
#' }
#' @param profiles Tibble. User profile information from \\code{\\link{get_profiles}}
#'   containing handle, displayName, description and other profile details
#' @param prop Numeric. Proportion of users to include in visualization (0-1).
#'   Use smaller values for large networks to improve performance (default 1.0)
#'
#' @return An interactive HTML widget (threejs object) that displays:
#' \\itemize{
#'   \\item{Nodes representing users, colored by community}
#'   \\item{Edges representing follow relationships}
#'   \\item{Interactive controls for rotation, zoom, and exploration}
#'   \\item{Hover tooltips showing user information}
#' }
#'
#' @details
#' The visualization process includes:
#' \\enumerate{
#'   \\item{Community detection using random walk algorithm}
#'   \\item{Color assignment based on community membership}
#'   \\item{Node labeling with user display names and descriptions}
#'   \\item{3D layout generation for optimal viewing}
#' }
#'
#' For large networks (1000+ users), consider using \\code{prop < 1} to sample
#' a subset for better performance. The widget works best with networks of
#' 50-500 users for detailed exploration.
#'
#' @family network-visualization
#' @seealso \\code{\\link{build_network}}, \\code{\\link{add_metrics}},
#'   \\code{\\link{trim_net}}
#'
#' @examples
#' \\dontrun{
#' # Build a network for visualization
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' network <- build_network(
#'   key_actors = c("scientist.bsky.social", "researcher.bsky.social"),
#'   keywords = c("science", "research", "academic"),
#'   token = auth$accessJwt,
#'   refresh_tok = auth$refreshJwt,
#'   threshold = 15,
#'   prop = 0.3  # Sample 30% for manageable size
#' )
#'
#' # Create full network visualization
#' full_widget <- create_widget(network$net, network$profiles, prop = 1.0)
#'
#' # Display the interactive visualization
#' full_widget
#'
#' # Create smaller sample for performance
#' sample_widget <- create_widget(network$net, network$profiles, prop = 0.5)
#' sample_widget
#'
#' # For very large networks, use even smaller samples
#' if (nrow(network$profiles) > 500) {
#'   performance_widget <- create_widget(network$net, network$profiles, prop = 0.2)
#' } else {
#'   performance_widget <- create_widget(network$net, network$profiles, prop = 0.8)
#' }
#'
#' # Save widget as HTML file for sharing
#' if (requireNamespace("htmlwidgets", quietly = TRUE)) {
#'   htmlwidgets::saveWidget(full_widget, "network_visualization.html")
#'   message("Visualization saved as network_visualization.html")
#' }
#'
#' # Customize for specific communities
#' # Filter to show only the largest communities
#' profiles_with_metrics <- add_metrics(network$profiles, network$net)
#' large_communities <- profiles_with_metrics[
#'   profiles_with_metrics$community %in% c(1, 2, 3),  # Top 3 communities
#' ]
#' filtered_net <- network$net[
#'   network$net$actor_handle %in% large_communities$handle &
#'   network$net$follows_handle %in% large_communities$handle,
#' ]
#' focused_widget <- create_widget(filtered_net, large_communities, prop = 1.0)
#' focused_widget
#' }
#'
#' @importFrom igraph V
#' @importFrom tidygraph activate as_tbl_graph
#' @export
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

#' Build complete network analysis pipeline
#'
#' Executes the complete network analysis workflow: initializes a network from key actors,
#' expands it iteratively, trims to final size, gets detailed profiles, creates
#' visualizations, and generates text analysis. This is the main high-level function
#' for comprehensive Bluesky network analysis.
#'
#' @param key_actors Character vector. Handles of central users to start the network from
#' @param keywords Character vector. Keywords for filtering users into the network
#' @param token Character. Authentication token from \code{\link{get_token}}
#' @param refresh_tok Character. Refresh token for long-running operations
#' @param threshold Numeric. Inclusion threshold for network expansion:
#' \describe{
#'   \item{>= 1}{Minimum followers from existing network required}
#'   \item{< 1}{Proportion of network that must follow a prospect}
#' }
#' @param prop Numeric. Proportion of users to sample for 3D visualization
#'   (0-1, where 1.0 includes all users)
#' @param ... Additional parameters passed to \code{\link{expand_net}}
#'   (e.g., max_iterations, sample_size, save_net)
#'
#' @return A comprehensive list containing all network analysis results:
#' \describe{
#'   \item{net}{Tibble. Final expanded network with follow relationships}
#'   \item{profiles}{Tibble. Detailed profile information for all network members}
#'   \item{metrics}{Tibble. Network metrics (centrality, community detection)}
#'   \item{widget}{HTML widget. Interactive 3D network visualization}
#'   \item{word_analysis}{Tibble. Word frequency analysis of profile descriptions}
#'   \item{token}{Character. Updated access token}
#'   \item{refresh_tok}{Character. Updated refresh token}
#' }
#'
#' @family network-building
#' @seealso \code{\link{init_net}}, \code{\link{expand_net}},
#'   \code{\link{add_metrics}}, \code{\link{create_widget}}
#'
#' @examples
#' \dontrun{
#' # Complete network analysis for science communicators
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#'
#' # Build comprehensive network
#' science_network <- build_network(
#'   key_actors = c("example.scientist.bsky.social", "researcher.bsky.social"),
#'   keywords = c("research", "science", "academic", "PhD", "university"),
#'   token = auth$accessJwt,
#'   refresh_tok = auth$refreshJwt,
#'   threshold = 10,      # Need 10+ mutual follows for inclusion
#'   prop = 0.5,          # Sample 50% for visualization
#'   max_iterations = 15, # Limit expansion iterations
#'   save_net = TRUE      # Save progress incrementally
#' )
#'
#' # Explore the results
#' print(paste("Network has", nrow(science_network$net), "connections"))
#' print(paste("Among", nrow(science_network$profiles), "unique users"))
#'
#' # View the interactive visualization
#' science_network$widget
#'
#' # Examine top words in user descriptions
#' head(science_network$word_analysis, 20)
#'
#' # Find most central users
#' top_central <- science_network$profiles[
#'   order(science_network$profiles$betweenness, decreasing = TRUE),
#' ][1:10, c("displayName", "handle", "description")]
#' print(top_central)
#' }
#'
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
