# Add network analysis metrics to user profiles

Computes and adds comprehensive network analysis metrics to user profile
data. This function calculates centrality measures, community detection,
and PageRank scores to identify influential users and network structure
within your Bluesky social network.

## Usage

``` r
add_metrics(profiles, net)
```

## Arguments

- profiles:

  Tibble. User profile information from
  [`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)
  containing at least handle and other profile details

- net:

  Tibble. Network edge list with follow relationships containing:

  actor_handle

  :   Character. User who is following another

  follows_handle

  :   Character. User being followed

## Value

Tibble with original profile data enhanced with network metrics:

- centrality:

  Numeric. Betweenness centrality score (influence as bridge)

- community:

  Integer. Community assignment from cluster analysis

- pageRank:

  Numeric. PageRank score (influence based on follower quality)

- insideFollowers:

  Integer. Number of followers within this network

- community_label:

  Character. Descriptive label for the community

Plus all original profile columns (handle, displayName, description,
etc.)

## Details

The function performs several network analysis computations:

- Betweenness centrality: Identifies users who act as bridges between
  communities

- Community detection: Uses random walks to find densely connected
  groups

- PageRank: Measures influence based on follower network quality

- Inside followers: Counts followers within the analyzed network subset

- Community labels: Generates descriptive labels using TF-IDF of user
  bios

## See also

[`build_network`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`com_labels`](https://lassehjorthmadsen.github.io/blueskynet/reference/com_labels.md),
[`create_widget`](https://lassehjorthmadsen.github.io/blueskynet/reference/create_widget.md)

Other network-analysis:
[`com_labels()`](https://lassehjorthmadsen.github.io/blueskynet/reference/com_labels.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Build a network first
auth <- get_token("your.handle.bsky.social", "your-app-password")
network_result <- build_network(
  key_actors = c("scientist.bsky.social", "researcher.bsky.social"),
  keywords = c("science", "research", "academic"),
  token = auth$accessJwt,
  refresh_tok = auth$refreshJwt,
  threshold = 10
)

# Add comprehensive metrics to profiles
enhanced_profiles <- add_metrics(network_result$profiles, network_result$net)

# Examine the most central (influential) users
top_central <- enhanced_profiles[
  order(enhanced_profiles$centrality, decreasing = TRUE),
][1:10, c("displayName", "handle", "centrality", "pageRank")]
print(top_central)

# Find the most influential users by PageRank
top_pagerank <- enhanced_profiles[
  order(enhanced_profiles$pageRank, decreasing = TRUE),
][1:10, c("displayName", "handle", "pageRank", "followersCount")]
print(top_pagerank)

# Analyze community structure
community_summary <- enhanced_profiles |>
  group_by(community, community_label) |>
  summarise(
    members = n(),
    avg_followers = mean(followersCount, na.rm = TRUE),
    avg_centrality = mean(centrality, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(members))
print(community_summary)

# Find users who bridge communities (high centrality)
bridge_users <- enhanced_profiles[
  enhanced_profiles$centrality > quantile(enhanced_profiles$centrality, 0.9, na.rm = TRUE),
  c("displayName", "handle", "centrality", "community_label")
]
print(bridge_users)

# Compare internal vs external influence
influence_comparison <- enhanced_profiles |>
  select(handle, followersCount, insideFollowers, pageRank) |>
  mutate(
    external_followers = followersCount - insideFollowers,
    influence_ratio = insideFollowers / followersCount
  ) |>
  arrange(desc(influence_ratio))
head(influence_comparison, 10)
} # }
```
