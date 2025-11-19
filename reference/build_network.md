# Build complete network analysis pipeline

Executes the complete network analysis workflow: initializes a network
from key actors, expands it iteratively, trims to final size, gets
detailed profiles, creates visualizations, and generates text analysis.
This is the main high-level function for comprehensive Bluesky network
analysis.

## Usage

``` r
build_network(key_actors, keywords, token, refresh_tok, threshold, prop, ...)
```

## Arguments

- key_actors:

  Character vector. Handles of central users to start the network from

- keywords:

  Character vector. Keywords for filtering users into the network

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- refresh_tok:

  Character. Refresh token for long-running operations

- threshold:

  Numeric. Inclusion threshold for network expansion:

  \>= 1

  :   Minimum followers from existing network required

  \< 1

  :   Proportion of network that must follow a prospect

- prop:

  Numeric. Proportion of users to sample for 3D visualization (0-1,
  where 1.0 includes all users)

- ...:

  Additional parameters passed to
  [`expand_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md)
  (e.g., max_iterations, sample_size, save_net)

## Value

A comprehensive list containing all network analysis results:

- net:

  Tibble. Final expanded network with follow relationships

- profiles:

  Tibble. Detailed profile information for all network members

- metrics:

  Tibble. Network metrics (centrality, community detection)

- widget:

  HTML widget. Interactive 3D network visualization

- word_analysis:

  Tibble. Word frequency analysis of profile descriptions

- token:

  Character. Updated access token

- refresh_tok:

  Character. Updated refresh token

## See also

[`init_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/init_net.md),
[`expand_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md),
[`add_metrics`](https://lassehjorthmadsen.github.io/blueskynet/reference/add_metrics.md),
[`create_widget`](https://lassehjorthmadsen.github.io/blueskynet/reference/create_widget.md)

Other network-building:
[`expand_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md),
[`init_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/init_net.md),
[`trim_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/trim_net.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Complete network analysis for science communicators
auth <- get_token("your.handle.bsky.social", "your-app-password")

# Build comprehensive network
science_network <- build_network(
  key_actors = c("example.scientist.bsky.social", "researcher.bsky.social"),
  keywords = c("research", "science", "academic", "PhD", "university"),
  token = auth$accessJwt,
  refresh_tok = auth$refreshJwt,
  threshold = 10,      # Need 10+ mutual follows for inclusion
  prop = 0.5,          # Sample 50% for visualization
  max_iterations = 15, # Limit expansion iterations
  save_net = TRUE      # Save progress incrementally
)

# Explore the results
print(paste("Network has", nrow(science_network$net), "connections"))
print(paste("Among", nrow(science_network$profiles), "unique users"))

# View the interactive visualization
science_network$widget

# Examine top words in user descriptions
head(science_network$word_analysis, 20)

# Find most central users
top_central <- science_network$profiles[
  order(science_network$profiles$betweenness, decreasing = TRUE),
][1:10, c("displayName", "handle", "description")]
print(top_central)
} # }
```
