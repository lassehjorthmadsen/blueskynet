# Get followers of a Bluesky user

Retrieves all users who follow a specific account on Bluesky Social.
This is the inverse of
[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md) -
while that shows who a user follows, this shows who follows them.
Includes robust error handling with automatic retries for reliable data
collection.

## Usage

``` r
get_followers(actor, token, max_retries = 3, retry_delay = 5)
```

## Arguments

- actor:

  Character. User handle (e.g., "username.bsky.social") or DID of the
  account whose followers you want to retrieve

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- max_retries:

  Integer. Number of times to retry on failure (default 3)

- retry_delay:

  Numeric. Delay in seconds between retries (default 5)

## Value

A tibble with information about followers:

- handle:

  Character. The follower's handle

- did:

  Character. The follower's DID

- displayName:

  Character. The follower's display name

- description:

  Character. The follower's bio

- followersCount:

  Integer. Number of followers the follower has

- followsCount:

  Integer. Number of accounts the follower follows

- createdAt:

  Character. When the follow relationship was created

Returns `NULL` if the user doesn't exist or is inaccessible.

## Lexicon references

[lexicons/app/bsky/graph/getFollowers.json](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollowers.json)

## See also

[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

Other api-wrappers:
[`get_follows()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_profiles()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md),
[`get_user_posts()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_user_posts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt

# Get followers of a popular account
followers <- get_followers("neilhimself.neilgaiman.com", token)
print(paste("User has", nrow(followers), "followers"))

# Analyze follower demographics
follower_profiles <- get_profiles(followers$handle[1:100], token)
print(summary(follower_profiles$followersCount))

# Compare follows vs followers for reciprocity analysis
user_handle <- "example.bsky.social"
follows <- get_follows(user_handle, token)
followers <- get_followers(user_handle, token)

# Find mutual connections (people who follow each other)
mutual <- intersect(follows$handle, followers$handle)
print(paste("Mutual connections:", length(mutual)))

# Identify influential followers (high follower count)
influential <- followers[followers$followersCount > 1000, ]
head(influential[, c("displayName", "handle", "followersCount")])
} # }
```
