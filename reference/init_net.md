# Initialize a network from key actors

Creates an initial network by getting all the accounts that key actors
follow, then filtering those accounts based on profile keywords. This
forms the seed network that can later be expanded using
[`expand_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md).

## Usage

``` r
init_net(key_actors, keywords, token, refresh_tok)
```

## Arguments

- key_actors:

  Character vector. Handles (e.g., "username.bsky.social") of the
  central actors whose follows will form the initial network

- keywords:

  Character vector. Keywords to search for in user profile descriptions
  to determine if they should be included in the network

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- refresh_tok:

  Character. Refresh token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)
  for long-running operations. Token will be refreshed automatically
  during processing to prevent expiration with large numbers of key
  actors.

## Value

A list containing the initial network results:

- net:

  Tibble. Network edges with follow relationships

- token:

  Character. Updated access token (may have been refreshed)

- refresh_tok:

  Character. Updated refresh token

The net tibble contains:

- actor_handle:

  Character. Handle of the user doing the following

- follows_handle:

  Character. Handle of the user being followed

This represents the initial network structure where each row is a follow
relationship between two users.

## See also

[`expand_net`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md),
[`build_network`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md)

Other network-building:
[`build_network()`](https://lassehjorthmadsen.github.io/blueskynet/reference/build_network.md),
[`expand_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/expand_net.md),
[`trim_net()`](https://lassehjorthmadsen.github.io/blueskynet/reference/trim_net.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt
refresh_tok <- auth$refreshJwt

# Create initial network from science communicators
key_scientists <- c("neilhimself.neilgaiman.com", "example.scientist.bsky.social")
science_keywords <- c("scientist", "researcher", "academic", "PhD")

result <- init_net(key_scientists, science_keywords, token, refresh_tok)
initial_net <- result$net
token <- result$token  # Updated token
refresh_tok <- result$refresh_tok  # Updated refresh token

print(paste("Initial network has", nrow(initial_net), "connections"))

# Examine the network structure
unique_actors <- length(unique(c(initial_net$actor_handle, initial_net$follows_handle)))
print(paste("Network contains", unique_actors, "unique users"))
} # }
```
