# Get authentication token for Bluesky API

Authenticates with the Bluesky API using your handle and app password to
obtain access and refresh tokens for subsequent API calls.

## Usage

``` r
get_token(identifier, password)
```

## Arguments

- identifier:

  Character. Your Bluesky handle (e.g., "username.bsky.social") or email
  address

- password:

  Character. Your Bluesky app password (not your regular password).
  Create one at https://bsky.app/settings/app-passwords

## Value

A list containing authentication information:

- accessJwt:

  Character. Access token for API calls

- refreshJwt:

  Character. Refresh token for renewing access

- handle:

  Character. Your verified handle

- did:

  Character. Your decentralized identifier (DID)

- email:

  Character. Your email address

## See also

[`refresh_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/refresh_token.md),
[`verify_token`](https://lassehjorthmadsen.github.io/blueskynet/reference/verify_token.md)

Other authentication:
[`refresh_token()`](https://lassehjorthmadsen.github.io/blueskynet/reference/refresh_token.md),
[`verify_token()`](https://lassehjorthmadsen.github.io/blueskynet/reference/verify_token.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate with Bluesky (requires valid credentials)
auth <- get_token("your.handle.bsky.social", "your-app-password")

# Extract tokens for use in other functions
access_token <- auth$accessJwt
refresh_token <- auth$refreshJwt
my_did <- auth$did

# Verify the token works
verify_token(access_token)
} # }
```
