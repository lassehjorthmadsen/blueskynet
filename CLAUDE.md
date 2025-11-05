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