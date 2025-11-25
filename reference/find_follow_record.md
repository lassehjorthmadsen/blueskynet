# Find follow record for specific actor

Searches through your complete follow records to find the specific
record for a given user. This is essential for unfollow operations since
you need the record key (rkey) from the original follow record to delete
it.

## Usage

``` r
find_follow_record(follow_records, actor_did)
```

## Arguments

- follow_records:

  List. Output from
  [`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md)
  containing all your follow record objects

- actor_did:

  Character. The DID (decentralized identifier) of the user you want to
  find the follow record for

## Value

The complete follow record object if found, \codeNULL if the user is not
in your follows. The record contains:

- uri:

  Character. Record URI containing the rkey needed for unfollowing

- cid:

  Character. Content identifier

- value:

  List. Record metadata including subject DID and creation time

## See also

[`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md),
[`unfollow_actor`](https://lassehjorthmadsen.github.io/blueskynet/reference/unfollow_actor.md),
[`extract_follow_subjects`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md)

Other follow-management:
[`extract_follow_subjects()`](https://lassehjorthmadsen.github.io/blueskynet/reference/extract_follow_subjects.md),
[`follow_actor()`](https://lassehjorthmadsen.github.io/blueskynet/reference/follow_actor.md),
[`get_all_follow_records()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md),
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

# Find a specific user's profile to get their DID
target_profile <- get_profiles("example.bsky.social", token)
target_did <- target_profile$did

# Find the follow record for that user
follow_record <- find_follow_record(all_follows, target_did)

if (!is.null(follow_record)) {
  message("Found follow record for user!")

  # Extract the rkey needed for unfollowing
  rkey <- basename(follow_record$uri)
  message("Record key: ", rkey)

  # Unfollow the user
  result <- unfollow_actor(my_did, rkey, token)
  if (!is.null(result)) {
    message("Successfully unfollowed user!")
  }
} else {
  message("You are not following this user")
}

# Batch processing: check if you follow multiple users
users_to_check <- c("user1.bsky.social", "user2.bsky.social", "user3.bsky.social")
check_profiles <- get_profiles(users_to_check, token)

follow_status <- data.frame(
  handle = check_profiles$handle,
  following = sapply(check_profiles$did, function(did) {
    !is.null(find_follow_record(all_follows, did))
  })
)
print(follow_status)

# Conditional unfollowing based on criteria
followed_dids <- extract_follow_subjects(all_follows)
followed_profiles <- get_profiles(followed_dids[1:50], token)  # Sample for demo

# Unfollow users with very low activity (< 5 posts)
inactive_users <- followed_profiles[followed_profiles$postsCount < 5, ]

for (did in inactive_users$did) {
  record <- find_follow_record(all_follows, did)
  if (!is.null(record)) {
    rkey <- basename(record$uri)
    unfollow_actor(my_did, rkey, token)
    message("Unfollowed inactive user: ", inactive_users$handle[inactive_users$did == did])
    Sys.sleep(1) # Rate limiting
  }
}
} # }
```
