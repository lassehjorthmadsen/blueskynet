# Generate labels for network communities

Creates descriptive labels for network communities by analyzing the most
frequent words (using TF-IDF weighting) in user profile descriptions
within each community.

## Usage

``` r
com_labels(profiles, top = 3)
```

## Arguments

- profiles:

  Data frame or tibble with profile information, must contain:

  community

  :   Integer. Community assignment for each user

  description

  :   Character. User profile descriptions/bios to analyze

- top:

  Integer. Number of top words to include in each label (default 3)

## Value

A tibble with community labels:

- community:

  Integer. Community ID

- community_label:

  Character. Descriptive label with top keywords

## See also

[`add_metrics`](https://lassehjorthmadsen.github.io/blueskynet/reference/add_metrics.md),
[`word_freqs`](https://lassehjorthmadsen.github.io/blueskynet/reference/word_freqs.md)

Other network-analysis:
[`add_metrics()`](https://lassehjorthmadsen.github.io/blueskynet/reference/add_metrics.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")

# Build a network to get community-assigned profiles
network_result <- build_network(
  key_actors = c("scientist.bsky.social", "researcher.bsky.social"),
  keywords = c("science", "research", "academic"),
  token = auth$accessJwt,
  refresh_tok = auth$refreshJwt,
  threshold = 10
)

# Add network metrics to get community assignments
profiles_with_communities <- add_metrics(network_result$profiles, network_result$net)

# Generate descriptive labels for each community
community_labels <- com_labels(profiles_with_communities, top = 3)
print(community_labels)

# View the most common words for each community
head(community_labels)
} # }
```
