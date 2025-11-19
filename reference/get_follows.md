# Get accounts followed by a user

Retrieves all accounts that a specific user follows on Bluesky Social.
Includes robust error handling and automatic retry logic for network
issues.

## Usage

``` r
get_follows(actor, token, max_retries = 3, retry_delay = 5)
```

## Arguments

- actor:

  Character. User handle (e.g., "username.bsky.social") or DID of the
  account whose follows you want to retrieve

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- max_retries:

  Integer. Number of times to retry on failure (default 3)

- retry_delay:

  Numeric. Delay in seconds between retries (default 5)

## Value

A tibble with information about followed accounts:

- handle:

  Character. The followed user's handle

- did:

  Character. The followed user's DID

- displayName:

  Character. The followed user's display name

- description:

  Character. The followed user's bio

- followersCount:

  Integer. Number of followers the followed user has

- followsCount:

  Integer. Number of accounts the followed user follows

- createdAt:

  Character. When the follow relationship was created

## Lexicon references

[lexicons/app/bsky/graph/getFollows.json](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/graph/getFollows.json)

## See also

[`get_followers`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_followers.md),
[`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

Other api-wrappers:
[`get_followers()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_followers.md),
[`get_profiles()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md),
[`get_user_posts()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_user_posts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt

# Get who Neil Gaiman follows
follows <- get_follows("neilhimself.neilgaiman.com", token)
head(follows)

# Get follows for multiple users
users <- c("example1.bsky.social", "example2.bsky.social")
all_follows <- lapply(users, get_follows, token = token)
names(all_follows) <- users
} # }
```
