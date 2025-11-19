# Get profile information for Bluesky users

Retrieves detailed profile information for one or more users on Bluesky
Social. Includes robust error handling with automatic retries and
efficient batch processing for multiple users.

## Usage

``` r
get_profiles(actors, token, chunksize = 25, max_retries = 3, retry_delay = 5)
```

## Arguments

- actors:

  Character vector. User handles (e.g., "username.bsky.social") or DIDs
  of users whose profiles you want to retrieve

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- chunksize:

  Integer. Number of actors per API request for batch processing
  (default 25, which is the current API maximum)

- max_retries:

  Integer. Number of times to retry on failure (default 3)

- retry_delay:

  Numeric. Delay in seconds between retries (default 5)

## Value

A tibble with detailed profile information:

- handle:

  Character. User's handle (e.g., "user.bsky.social")

- did:

  Character. User's decentralized identifier

- displayName:

  Character. User's display name

- description:

  Character. User's bio/profile description

- avatar:

  Character. URL to user's avatar image

- banner:

  Character. URL to user's banner image

- followersCount:

  Integer. Number of followers

- followsCount:

  Integer. Number of accounts they follow

- postsCount:

  Integer. Number of posts they've made

- createdAt:

  Character. When the account was created

Returns `NULL` for users that don't exist or are inaccessible.

## See also

[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_followers`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_followers.md),
[`get_user_posts`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_user_posts.md)

Other api-wrappers:
[`get_followers()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_followers.md),
[`get_follows()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_user_posts()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_user_posts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt

# Get profile for a single user
profile <- get_profiles("neilhimself.neilgaiman.com", token)
print(profile)

# Get profiles for multiple users efficiently
users <- c("user1.bsky.social", "user2.bsky.social", "user3.bsky.social")
profiles <- get_profiles(users, token)
head(profiles)

# Use with network analysis
follows <- get_follows("example.bsky.social", token)
detailed_profiles <- get_profiles(follows$handle, token)

# Filter by follower count
popular_users <- profiles[profiles$followersCount > 1000, ]
} # }
```
