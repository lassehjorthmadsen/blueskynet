# Get complete follow records from user repository

Retrieves all follow records from a user's personal repository on
Bluesky. This provides more detailed follow relationship data than
[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
including record keys needed for
[`unfollow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md)
operations. Useful for follow/unfollow management and relationship
analysis.

## Usage

``` r
get_all_follow_records(my_did, token, max_retries = 3, retry_delay = 5)
```

## Arguments

- my_did:

  Character. Your decentralized identifier (DID) from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)
  response

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- max_retries:

  Integer. Maximum number of retries on failure (default 3)

- retry_delay:

  Numeric. Delay in seconds between retries (default 5)

## Value

A list of follow record objects, each containing:

- uri:

  Character. Unique record identifier (contains rkey)

- cid:

  Character. Content identifier

- value:

  List. Record content with 'subject' (target DID) and metadata

Each record represents one follow relationship you've created.

## See also

[`unfollow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md),
[`find_follow_record`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
[`extract_follow_subjects`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md)

Other follow-management:
[`extract_follow_subjects()`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md),
[`find_follow_record()`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
[`follow_actor()`](https://lassehjorthmadsen.github.io/blueskynet/reference/follow_actor.md),
[`unfollow_actor()`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt
my_did <- auth$did

# Get all your follow records
all_follows <- get_all_follow_records(my_did, token)
print(paste("You are following", length(all_follows), "users"))

# Extract just the DIDs of people you follow
followed_dids <- extract_follow_subjects(all_follows)
head(followed_dids)

# Find a specific follow record
target_profile <- get_profiles("example.bsky.social", token)
target_record <- find_follow_record(all_follows, target_profile$did)

if (!is.null(target_record)) {
  # Unfollow using the record key
  rkey <- basename(target_record$uri)
  unfollow_actor(my_did, rkey, token)
}

# Bulk unfollow inactive users (example workflow)
recent_active <- get_profiles(followed_dids[1:50], token)
old_follows <- recent_active[recent_active$postsCount < 5, ]

for (did in old_follows$did) {
  record <- find_follow_record(all_follows, did)
  if (!is.null(record)) {
    rkey <- basename(record$uri)
    unfollow_actor(my_did, rkey, token)
    Sys.sleep(1) # Rate limiting
  }
}
} # }
```
