# Clean and trim network to create cohesive community

Iteratively refines a network by removing isolated users and applying
follower thresholds to create a cohesive community where every user both
follows and is followed by others within the network. This produces
cleaner network visualizations and more meaningful community analysis.

## Usage

``` r
trim_net(net, threshold)
```

## Arguments

- net:

  Tibble. Network edge list with follow relationships containing:

  actor_handle

  :   Character. User who is following another

  follows_handle

  :   Character. User being followed

- threshold:

  Numeric. Inclusion threshold for users: \describe \item\>= 1Minimum
  number of followers within the network required \item\< 1Minimum
  proportion of network that must follow the user

## Value

Tibble. Cleaned network with the same structure as input but with:
\itemize \itemAll duplicate edges removed \itemInvalid handles and NA
values excluded \itemUsers below follower threshold removed \itemOnly
users who both follow and are followed within the network The resulting
network forms a more cohesive community for analysis.

## Details

The trimming process works iteratively: \enumerate \itemRemove duplicate
connections and invalid/missing handles \itemCount followers for each
user within the network \itemRemove users below the specified threshold
\itemKeep only users who appear as both followers and followed
\itemRepeat until the network stabilizes

This creates a "core community" where every member has meaningful
connections within the group, improving visualization quality and
analytical insights.

## See also

\code\linkexpand_net, \code\linkbuild_network, \code\linkadd_metrics

Other network-building:
[`build_network()`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`expand_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md),
[`init_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/init_net.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Build an initial network
auth <- get_token("your.handle.bsky.social", "your-app-password")
initial_net <- init_net(
  c("scientist1.bsky.social", "researcher2.bsky.social"),
  c("science", "research"),
  auth$accessJwt
)

# Expand the network
expanded <- expand_net(
  net = initial_net,
  keywords = c("science", "research", "academic"),
  token = auth$accessJwt,
  refresh_tok = auth$refreshJwt,
  threshold = 5,
  max_iterations = 10
)

# Before trimming - show network size
cat("Before trimming:")
cat("  Unique actors:", length(unique(expanded$net$actor_handle)))
cat("  Unique follows:", length(unique(expanded$net$follows_handle)))
cat("  Total connections:", nrow(expanded$net))

# Trim to create cohesive community (need 10+ internal followers)
trimmed_net <- trim_net(expanded$net, threshold = 10)

# After trimming - show the refined network
cat("After trimming:")
cat("  Unique users:", length(unique(trimmed_net$actor_handle)))
cat("  Total connections:", nrow(trimmed_net))

# Verify all users both follow and are followed
actors <- unique(trimmed_net$actor_handle)
follows <- unique(trimmed_net$follows_handle)
cat("Network cohesion check:")
cat("  All actors also appear as follows:", all(actors %in% follows))
cat("  All follows also appear as actors:", all(follows %in% actors))

# Compare network density before and after
users_before <- length(unique(c(expanded$net$actor_handle, expanded$net$follows_handle)))
users_after <- length(unique(c(trimmed_net$actor_handle, trimmed_net$follows_handle)))
density_before <- nrow(expanded$net) / (users_before * (users_before - 1))
density_after <- nrow(trimmed_net) / (users_after * (users_after - 1))

cat("Network density improved from", round(density_before, 4), "to", round(density_after, 4))

# Use proportional threshold for smaller networks
# Require at least 20% of network to follow each user
proportional_trim <- trim_net(initial_net, threshold = 0.2)
} # }
```
