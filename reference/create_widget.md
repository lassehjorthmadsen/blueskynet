# Create interactive 3D network visualization widget

Creates an interactive 3D visualization of your Bluesky social network
using WebGL. The visualization shows users as nodes colored by community
membership and connections as edges, allowing you to explore network
structure, identify clusters, and understand relationship patterns in
your social network.

## Usage

``` r
create_widget(net, profiles, prop = 1)
```

## Arguments

- net:

  Tibble. Network edge list with follow relationships containing:

  actor_handle

  :   Character. User who is following another

  follows_handle

  :   Character. User being followed

- profiles:

  Tibble. User profile information from \code\linkget_profiles
  containing handle, displayName, description and other profile details

- prop:

  Numeric. Proportion of users to include in visualization (0-1). Use
  smaller values for large networks to improve performance (default 1.0)

## Value

An interactive HTML widget (threejs object) that displays: \itemize
\itemNodes representing users, colored by community \itemEdges
representing follow relationships \itemInteractive controls for
rotation, zoom, and exploration \itemHover tooltips showing user
information

## Details

The visualization process includes: \enumerate \itemCommunity detection
using random walk algorithm \itemColor assignment based on community
membership \itemNode labeling with user display names and descriptions
\item3D layout generation for optimal viewing

For large networks (1000+ users), consider using \codeprop \< 1 to
sample a subset for better performance. The widget works best with
networks of 50-500 users for detailed exploration.

## See also

\code\linkbuild_network, \code\linkadd_metrics, \code\linktrim_net

## Examples

``` r
if (FALSE) { # \dontrun{
# Build a network for visualization
auth <- get_token("your.handle.bsky.social", "your-app-password")
network <- build_network(
  key_actors = c("scientist.bsky.social", "researcher.bsky.social"),
  keywords = c("science", "research", "academic"),
  token = auth$accessJwt,
  refresh_tok = auth$refreshJwt,
  threshold = 15,
  prop = 0.3  # Sample 30% for manageable size
)

# Create full network visualization
full_widget <- create_widget(network$net, network$profiles, prop = 1.0)

# Display the interactive visualization
full_widget

# Create smaller sample for performance
sample_widget <- create_widget(network$net, network$profiles, prop = 0.5)
sample_widget

# For very large networks, use even smaller samples
if (nrow(network$profiles) > 500) {
  performance_widget <- create_widget(network$net, network$profiles, prop = 0.2)
} else {
  performance_widget <- create_widget(network$net, network$profiles, prop = 0.8)
}

# Save widget as HTML file for sharing
if (requireNamespace("htmlwidgets", quietly = TRUE)) {
  htmlwidgets::saveWidget(full_widget, "network_visualization.html")
  message("Visualization saved as network_visualization.html")
}

# Customize for specific communities
# Filter to show only the largest communities
profiles_with_metrics <- add_metrics(network$profiles, network$net)
large_communities <- profiles_with_metrics[
  profiles_with_metrics$community %in% c(1, 2, 3),  # Top 3 communities
]
filtered_net <- network$net[
  network$net$actor_handle %in% large_communities$handle &
  network$net$follows_handle %in% large_communities$handle,
]
focused_widget <- create_widget(filtered_net, large_communities, prop = 1.0)
focused_widget
} # }
```
