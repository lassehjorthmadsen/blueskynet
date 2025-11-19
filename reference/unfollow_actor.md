# Unfollow a user on Bluesky Social

Removes a follow relationship between your account and another user on
Bluesky Social. This is equivalent to clicking the "Unfollow" button on
a user's profile. Requires the record key of the follow relationship.

## Usage

``` r
unfollow_actor(my_did, rkey, token)
```

## Arguments

- my_did:

  Character. Your decentralized identifier (DID) obtained from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)
  response

- rkey:

  Character. Record key of the follow relationship to delete. Can be
  obtained from
  [`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md)
  or by parsing the URI from
  [`follow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/follow_actor.md)
  response

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

## Value

An httr2 response object confirming the deletion, or `NULL` if the
unfollow operation fails.

## See also

[`follow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/follow_actor.md),
[`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md),
[`find_follow_record`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md)

Other follow-management:
[`extract_follow_subjects()`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md),
[`find_follow_record()`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
[`follow_actor()`](https://lassehjorthmadsen.github.io/blueskynet/reference/follow_actor.md),
[`get_all_follow_records()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt
my_did <- auth$did

# Get all your follow records to find the one to delete
all_follows <- get_all_follow_records(my_did, token)

# Find the record for a specific user
target_profile <- get_profiles("example.bsky.social", token)
target_record <- find_follow_record(all_follows, target_profile$did)

if (!is.null(target_record)) {
  # Extract record key from URI (after the last slash)
  rkey <- basename(target_record$uri)

  # Unfollow the user
  result <- unfollow_actor(my_did, rkey, token)

  if (!is.null(result)) {
    message("Successfully unfollowed user!")
  }
}
} # }
```
