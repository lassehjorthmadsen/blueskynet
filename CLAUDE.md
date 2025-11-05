# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`blueskynet` is an R package for generating and analyzing social networks from Bluesky Social. The package provides tools to build networks based on user follows relationships, analyze network structures, and visualize networks with interactive 3D widgets.

## Package Development Commands

### Essential Development Workflow
```r
# Load the package for development
devtools::load_all()

# Generate documentation from roxygen comments
devtools::document()

# Check package for CRAN compliance
devtools::check()

# Install the package locally
devtools::install()

# Build package documentation website
pkgdown::build_site()
```

### Authentication Setup
Users must create a Bluesky app password and set environment variables:
```r
# Set environment variables in ~/.Renviron
BLUESKY_APP_PASS=your_app_password
BLUESKY_APP_USER=your.handle.bsky.social
```

## Code Architecture

### Core Module Structure

The package is organized into four main R files:

1. **`R/wrappers.R`** - Direct API wrapper functions for Bluesky endpoints:
   - `get_token()` - Authentication
   - `get_profiles()` - User profile data
   - `get_follows()` - Following relationships
   - `get_user_posts()` - User post data
   - `follow_actor()` - Follow users programmatically

2. **`R/algos.R`** - Network building and analysis algorithms:
   - `init_net()` - Create initial network from a key actor
   - `expand_net()` - Iteratively expand network using keyword filtering
   - `build_network()` - Complete network building pipeline
   - `add_metrics()` - Add network analysis metrics
   - `trim_net()` - Filter networks by criteria

3. **`R/helpers.R`** - Internal utility functions:
   - `resp2df()` - Convert API responses to data frames
   - `post2df()` - Parse post data from API responses
   - `check_wait()` - Handle API rate limiting
   - Token refresh and validation helpers

4. **`R/blueskynet-package.R`** - Package documentation and imports

### Key Architectural Patterns

**API Token Management**: The package handles Bluesky authentication with access tokens and refresh tokens. All API functions expect a valid token parameter and some can refresh tokens automatically during long-running operations.

**Network Data Structure**: Networks are represented as tibbles with two key columns:
- `actor_handle` - The user who is following
- `follows_handle` - The user being followed

**Iterative Network Expansion**: The `expand_net()` function uses a threshold-based approach to grow networks iteratively, filtering new candidates by keyword matching in user profiles and minimum follower counts.

**Rate Limiting**: The package includes built-in handling for Bluesky API rate limits with automatic waiting and token refresh capabilities.

## Development Workflow

### Testing Strategy
The package includes comprehensive unit tests using `testthat`:

```r
# Run all tests
devtools::test()

# Run tests with coverage
covr::package_coverage()
```

**Key Testing Principles:**
- **71 comprehensive tests** covering all major functionality
- **Mock data approach** for API functions (avoid live API calls in tests)
- **Edge case coverage** including Unicode text, empty inputs, large datasets
- **Input validation tests** for proper parameter checking
- **Performance tests** for medium-sized networks

**Test Organization:**
- `tests/testthat/test-helpers.R` - Utility functions (`word_freqs`, etc.)
- `tests/testthat/test-network-analysis.R` - Network algorithms
- `tests/testthat/test-api-input-validation.R` - API wrapper validation
- `tests/testthat/test-edge-cases.R` - Edge cases and performance

### CRAN Preparation Checklist
Achievement: **0 errors, 0 warnings** in R CMD check

**Critical Issues to Watch:**
1. **Documentation formatting** - Use single backslashes in roxygen (`\describe{}` not `\\describe{}`)
2. **Examples strategy** - Wrap API-dependent examples in `\dontrun{}`
3. **Function exports** - Ensure all documented functions are exported
4. **Dependencies** - All used packages must be in DESCRIPTION Imports
5. **ORCID placeholders** - Remove or replace placeholder ORCID IDs

```r
# Key CRAN checks
devtools::check(args = "--as-cran")
devtools::check_win_devel()  # Optional: check on Windows
```

### Testing and Validation
The package uses the `dev/` directory for development scripts and example data:
- `dev/demo.R` - Complete usage examples
- `dev/net/` - Sample network data files
- Development scripts for stress testing and error handling

### Documentation Generation
- Uses roxygen2 for function documentation
- pkgdown website generation configured in `_pkgdown.yml`
- Functions are categorized into "Wrapper functions" and "Network functions"

### Package Dependencies
Key dependencies include:
- `httr2` for API communication
- `dplyr`, `purrr` for data manipulation
- `igraph`, `tidygraph` for network analysis
- `threejs` for 3D network visualization
- `quanteda` for text analysis of user profiles

## Common Operations

### Building a Network
```r
# Authenticate
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt

# Create initial network
key_actor <- "example.bsky.social"
keywords <- c("researcher", "scientist")
net <- init_net(key_actor, keywords, token)

# Expand network iteratively
expanded <- expand_net(net, keywords, token, refresh_tok,
                      threshold = 30, max_iterations = 50)
```

### Token Management
Always handle token refresh in long-running operations:
```r
# Check token validity
verify_token(token)

# Refresh if needed
new_auth <- refresh_token(refresh_tok)
token <- new_auth$accessJwt
```

## Technical Insights & Code Quality

### Key Function Improvements Made
During development, several functions were enhanced for robustness:

**`extract_follow_subjects()` Enhancement:**
```r
# Before: Used sapply() which could return different types
sapply(follow_records, function(record) record$value$subject)

# After: Use vapply() for type safety
vapply(follow_records, function(record) record$value$subject, character(1))
```

**Input Validation Pattern:**
```r
# Always validate inputs early in functions
if (is.null(follow_records)) {
  stop("follow_records cannot be NULL")
}
if (length(follow_records) == 0) {
  return(character(0))
}
```

### Documentation Best Practices
**Roxygen2 Guidelines:**
- Use single backslashes: `\describe{}`, `\item{}`, `\code{}`
- Wrap API examples in `\dontrun{}` to prevent execution during check
- Include comprehensive parameter descriptions with type information
- Add cross-references with `\seealso` and function families

**Example Documentation Pattern:**
```r
#' @param handle Character vector. Bluesky handles (e.g., "user.bsky.social")
#' @param token Character. Authentication token from \code{\link{get_token}}
#'
#' @return A tibble with user profile information containing:
#' \describe{
#'   \item{handle}{Character. User handle}
#'   \item{displayName}{Character. Display name}
#'   \item{description}{Character. Profile bio}
#' }
#'
#' @examples
#' \dontrun{
#' auth <- get_token("your.handle.bsky.social", "your-app-password")
#' profiles <- get_profiles("example.bsky.social", auth$accessJwt)
#' }
```

### Git Workflow Patterns
**Commit Message Template:**
```
action: brief description

- Specific change 1 with technical details
- Specific change 2 with impact explanation
- Achievement metrics (e.g., "Package now passes R CMD check")

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```