# Expand network through iterative growth

Expands an initial network by iteratively finding new users who are
followed by many existing network members and match specified keywords.
This is the core algorithm for growing networks from a seed set of
users.

## Usage

``` r
expand_net(
  net,
  keywords,
  token,
  refresh_tok,
  save_net = FALSE,
  file_name,
  threshold,
  max_iterations,
  sample_size = Inf
)
```

## Arguments

- net:

  Tibble. Initial network with follow relationships, must contain:

  actor_handle

  :   Character. User who is following

  follows_handle

  :   Character. User being followed

- keywords:

  Character vector. Keywords to search for in user profile descriptions
  to determine network membership eligibility

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- refresh_tok:

  Character. Refresh token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)
  for long-running operations

- save_net:

  Logical. Should the network be saved incrementally during expansion to
  prevent data loss? (default FALSE)

- file_name:

  Character. File path for incremental saves. If not provided, defaults
  to 'dev/net/bignet_TIMESTAMP.rds'

- threshold:

  Numeric. Inclusion threshold for new users:

  \>= 1

  :   Minimum number of existing network members who must follow a
      prospect

  \< 1

  :   Fraction of network members who must follow a prospect

- max_iterations:

  Integer. Maximum number of expansion iterations (default 50)

- sample_size:

  Integer. Maximum prospects to consider per iteration. Use `Inf` for no
  limit (default), smaller values for testing

## Value

A list containing the expanded network results:

- net:

  Tibble. Expanded network with all follow relationships discovered

- token:

  Character. Updated access token (may have been refreshed)

- refresh_tok:

  Character. Updated refresh token

- profiles:

  Tibble. Profile information for all network members

- iterations:

  Integer. Number of iterations completed

## See also

[`init_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/init_net.md),
[`build_network`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`trim_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/trim_net.md)

Other network-building:
[`build_network()`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`init_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/init_net.md),
[`trim_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/trim_net.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Start with an initial network
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt
refresh_tok <- auth$refreshJwt

# Create initial network
initial <- init_net("example.scientist.bsky.social",
                    c("research", "science"), token)

# Expand the network - conservative approach
expanded <- expand_net(
  net = initial,
  keywords = c("research", "science", "academic", "PhD"),
  token = token,
  refresh_tok = refresh_tok,
  threshold = 5,        # Need 5+ followers from existing network
  max_iterations = 10,  # Limit iterations for testing
  save_net = TRUE       # Save progress incrementally
)

print(paste("Network grew from", nrow(initial), "to",
            nrow(expanded$net), "connections"))

# More aggressive expansion with lower threshold
large_expansion <- expand_net(
  net = expanded$net,
  keywords = c("research", "science", "academic"),
  token = expanded$token,
  refresh_tok = expanded$refresh_tok,
  threshold = 0.1,      # 10% of network must follow prospect
  max_iterations = 25
)
} # }
```
