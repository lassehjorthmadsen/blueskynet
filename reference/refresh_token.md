# Refresh authentication token for Bluesky API

Refreshes an expired access token using a refresh token. Access tokens
expire after a period of time, but refresh tokens can be used to obtain
new access tokens without re-authenticating.

## Usage

``` r
refresh_token(refresh_token)
```

## Arguments

- refresh_token:

  Character. The refresh token obtained from
  [`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md)

## Value

A list containing new authentication information:

- accessJwt:

  Character. New access token for API calls

- refreshJwt:

  Character. New refresh token for future renewals

- handle:

  Character. Your verified handle

- did:

  Character. Your decentralized identifier (DID)

## See also

[`get_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md),
[`verify_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/verify_token.md)

Other authentication:
[`get_token()`](https://lassehjorthmadsen.github.io/blueskynet/reference/get_token.md),
[`verify_token()`](https://lassehjorthmadsen.github.io/blueskynet/reference/verify_token.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# First authenticate to get tokens
auth <- get_token("your.handle.bsky.social", "your-app-password")

# Later, when access token expires, refresh it
new_auth <- refresh_token(auth$refreshJwt)
new_access_token <- new_auth$accessJwt

# Use the new token for API calls
profiles <- get_profiles("example.bsky.social", new_access_token)
} # }
```
