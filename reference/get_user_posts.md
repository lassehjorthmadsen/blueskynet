# Retrieve posts from a Bluesky user

Fetches posts from a specific user's timeline on Bluesky Social with
various filtering options. Useful for content analysis, engagement
tracking, and understanding user posting patterns. Includes pagination
support for large post histories and robust error handling for reliable
data collection.

## Usage

``` r
get_user_posts(
  actor,
  token,
  max_retries = 3,
  retry_delay = 5,
  filter = "posts_no_replies",
  limit = 100,
  return_df = TRUE
)
```

## Arguments

- actor:

  Character. User handle (e.g., "username.bsky.social") or DID of the
  user whose posts you want to retrieve

- token:

  Character. Authentication token from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

- max_retries:

  Integer. Number of times to retry on failure (default 3)

- retry_delay:

  Numeric. Delay in seconds between retries (default 5)

- filter:

  Character. Type of posts to retrieve (default "posts_no_replies"):

  posts_no_replies

  :   Original posts only, no replies

  posts_with_replies

  :   All posts including replies

  posts_with_media

  :   Posts containing images or videos

  posts_and_author_threads

  :   Posts and thread continuations

  posts_with_video

  :   Posts containing video content

- limit:

  Integer. Maximum number of posts to retrieve (default 100)

- return_df:

  Logical. Return as tibble (TRUE) or raw JSON list (FALSE)

## Value

If `return_df = TRUE`, a tibble with post information:

- actor:

  Character. The user who made the post

- uri:

  Character. Unique post identifier

- cid:

  Character. Content identifier

- author_did:

  Character. Author's DID

- author_handle:

  Character. Author's handle

- author_displayName:

  Character. Author's display name

- text:

  Character. Post text content

- created_at:

  Character. When the post was created

- reply_count:

  Integer. Number of replies

- repost_count:

  Integer. Number of reposts

- like_count:

  Integer. Number of likes

- quote_count:

  Integer. Number of quote posts

If `return_df = FALSE`, returns raw JSON response list.

## Endpoint documentation

[Endpoint
documentation](https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/feed/getAuthorFeed.json)

## See also

[`get_profiles`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md),
[`word_freqs`](https://lassehjorthmadsen.github.io/blueskynet/reference/word_freqs.md)

Other api-wrappers:
[`get_followers()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_followers.md),
[`get_follows()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_follows.md),
[`get_profiles()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_profiles.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first
auth <- get_token("your.handle.bsky.social", "your-app-password")
token <- auth$accessJwt

# Get recent posts from a user (no replies)
posts <- get_user_posts("neilhimself.neilgaiman.com", token, limit = 50)
head(posts[, c("text", "created_at", "like_count")])

# Get posts with media content
media_posts <- get_user_posts("photographer.bsky.social", token,
                              filter = "posts_with_media", limit = 20)

# Analyze posting patterns
user_posts <- get_user_posts("example.bsky.social", token, limit = 200)

# Most engaging posts
top_posts <- user_posts[order(user_posts$like_count, decreasing = TRUE), ]
head(top_posts[, c("text", "like_count", "repost_count")], 10)

# Text analysis of posts
post_words <- word_freqs(user_posts$text, top = 20)
head(post_words)

# Get raw JSON for custom processing
raw_posts <- get_user_posts("example.bsky.social", token,
                            return_df = FALSE, limit = 10)
str(raw_posts[[1]]) # Examine structure
} # }
```
