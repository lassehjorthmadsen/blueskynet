# Extract subject DIDs from follow records

Extracts the DIDs (decentralized identifiers) of all users you are
following from the complete follow records retrieved by
[`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md).
This is useful for getting a simple list of who you follow for analysis
or bulk operations without the full record metadata.

## Usage

``` r
extract_follow_subjects(follow_records)
```

## Arguments

- follow_records:

  List. Output from
  [`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md)
  containing complete follow record objects

## Value

Character vector of DIDs for all users you are following. Each DID is a
unique identifier like "did:plc:abc123xyz..."

## See also

[`get_all_follow_records`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_all_follow_records.md),
[`find_follow_record`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
[`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

Other follow-management:
[`find_follow_record()`](https://lassehjorthmadsen.github.io/blueskynet/reference/find_follow_record.md),
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
print(paste("You have", length(all_follows), "follow records"))

# Extract just the DIDs of people you follow
followed_dids <- extract_follow_subjects(all_follows)
print(paste("You are following", length(followed_dids), "unique users"))
head(followed_dids, 5)

# Use DIDs to get detailed profile information
sample_profiles <- get_profiles(followed_dids[1:10], token)
print(sample_profiles[, c("displayName", "handle", "followersCount")])

# Count follows by domain
handles_from_dids <- get_profiles(followed_dids, token)$handle
domains <- sapply(strsplit(handles_from_dids, "\\\\."), function(x) {
  if (length(x) >= 2) paste(tail(x, 2), collapse = ".") else x[1]
})
domain_counts <- sort(table(domains), decreasing = TRUE)
head(domain_counts, 10)

# Find users you follow who follow each other (mutual connections)
mutual_matrix <- matrix(FALSE, length(followed_dids), length(followed_dids))
for (i in seq_along(followed_dids)) {
  user_follows <- get_follows(followed_dids[i], token)
  if (!is.null(user_follows)) {
    user_follow_dids <- get_profiles(user_follows$handle, token)$did
    mutual_matrix[i, ] <- followed_dids %in% user_follow_dids
  }
  Sys.sleep(1) # Rate limiting
}
} # }
```
