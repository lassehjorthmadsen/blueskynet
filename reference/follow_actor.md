# Follow a user on Bluesky Social

Creates a follow relationship between your account and another user on
Bluesky Social. This is equivalent to clicking the "Follow" button on a
user's profile.

## Usage

``` r
follow_actor(my_did, actor_did, token)
```

## Arguments

- my_did:

  Character. Your decentralized identifier (DID) obtained from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)
  response

- actor_did:

  Character. The DID of the user you want to follow. Can be obtained
  using
  [`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

## Value

An httr2 response object containing:

- uri:

  Character. URI of the created follow record

- cid:

  Character. Content identifier for the follow record

Returns `NULL` if the follow operation fails.

## See also

[`unfollow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md),
[`get_follows`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

Other follow-management:
[`extract_follow_subjects()`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md),
[`find_follow_record()`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
[`get_all_follow_records()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md),
[`unfollow_actor()`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt
my_did <- auth$did

# Get the DID of the user you want to follow
target_profile <- get_profiles("neilhimself.neilgaiman.com", token)
target_did <- target_profile$did

# Follow the user
result <- follow_actor(my_did, target_did, token)

if (!is.null(result)) {
  message("Successfully followed user!")
}

# Follow multiple users
users_to_follow <- c("user1.bsky.social", "user2.bsky.social")
profiles <- get_profiles(users_to_follow, token)

for (i in 1:nrow(profiles)) {
  result <- follow_actor(my_did, profiles$did[i], token)
  Sys.sleep(1) # Be respectful with rate limits
}
} # }
```
