# blueskynet 0.1.0

## Major Features

* **Complete API Coverage**: Full wrapper functions for Bluesky Social API including authentication, profile retrieval, follow management, and content access
* **Network Building**: Comprehensive tools for building social networks from seed users with keyword filtering and iterative expansion
* **Network Analysis**: Advanced network metrics including centrality measures, community detection, and PageRank calculations
* **Interactive Visualization**: 3D network visualizations using WebGL with community-based coloring and interactive exploration
* **Text Analysis**: TF-IDF based community labeling and word frequency analysis of user profiles
* **Follow Management**: Complete follow/unfollow functionality with bulk operations and record management

## Core Functions

### Authentication & API Access
* `get_token()` - Authenticate with Bluesky API using handle and app password
* `refresh_token()` - Refresh expired authentication tokens
* `verify_token()` - Validate token status
* `get_profiles()` - Retrieve detailed user profile information
* `get_follows()` - Get accounts followed by a user with error handling and pagination
* `get_followers()` - Get followers of a user with robust retry logic
* `get_user_posts()` - Retrieve user posts with filtering options

### Follow Management
* `follow_actor()` - Follow users programmatically
* `unfollow_actor()` - Unfollow users with record key management
* `get_all_follow_records()` - Complete follow record retrieval with pagination
* `extract_follow_subjects()` - Extract DIDs from follow records
* `find_follow_record()` - Find specific follow records for management

### Network Building & Analysis
* `init_net()` - Initialize networks from key actors and keywords
* `expand_net()` - Iteratively expand networks with threshold-based inclusion
* `trim_net()` - Clean networks to create cohesive communities
* `build_network()` - Complete network analysis pipeline
* `add_metrics()` - Comprehensive network metrics calculation
* `com_labels()` - Generate descriptive community labels using TF-IDF

### Visualization & Utilities
* `create_widget()` - Interactive 3D network visualization with WebGL
* `word_freqs()` - Text analysis and word frequency calculation

## Technical Highlights

* **Robust Error Handling**: Comprehensive retry logic for network requests with rate limiting awareness
* **Scalable Design**: Efficient batch processing for large networks with memory management
* **CRAN Ready**: Full documentation coverage with 0 errors and 0 warnings in R CMD check
* **Professional Documentation**: Comprehensive examples, parameter descriptions, and cross-references
* **API Best Practices**: Proper authentication handling, token refresh, and rate limiting

## Requirements

* R (>= 4.1.0) for native pipe operator support
* Active Bluesky Social account with app password for API access
* Network visualization requires WebGL-capable browser

## Breaking Changes

* This is the initial CRAN release - no breaking changes from previous versions