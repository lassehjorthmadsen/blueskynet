# Test script for token refresh fixes in init_net() and build_network()
# Tests the fix for: Error in `.data$actor_handle`: Column `actor_handle` not found in `.data`.

library(tidyverse)
devtools::load_all()

# ============================================================================
# SETUP
# ============================================================================

cat("=== SETUP ===\n")

# Authorization
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")

if (password == "" || identifier == "") {
  stop("Please set BLUESKY_APP_PASS and BLUESKY_APP_USER environment variables")
}

cat("Getting authentication token...\n")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt
cat("✓ Authentication successful\n")

# Load test data
cat("Loading test data...\n")
net2 <- read_rds("../blueskyanalyses/data/research_net_2025-11-18.rds")
keywords <- read_lines("../blueskyanalyses/data/research_keywords.txt")
key_actors <- unique(net2$actor_handle)

cat("✓ Loaded", length(key_actors), "unique key actors\n")
cat("✓ Loaded", length(keywords), "keywords\n")

# Test parameters
threshold <- 0.01
max_iterations <- 2
sample_size <- Inf

# ============================================================================
# TEST 1: SMALL SAMPLE TO VERIFY BASIC FUNCTIONALITY
# ============================================================================

cat("\n=== TEST 1: Small Sample (5 actors) ===\n")
cat(
  "Testing basic functionality with small sample to ensure we didn't break anything...\n"
)

small_actors <- sample(key_actors, 5)
cat("Selected actors:", paste(small_actors, collapse = ", "), "\n")

tryCatch(
  {
    small_result <- init_net(small_actors, keywords, token, refresh_tok)
    cat("✓ init_net() succeeded with 5 actors\n")
    cat("  - Network size:", nrow(small_result$net), "connections\n")
    cat("  - Unique actors:", n_distinct(small_result$net$actor_handle), "\n")
    cat(
      "  - Unique follows:",
      n_distinct(small_result$net$follows_handle),
      "\n"
    )
    cat("  - Token refreshed:", !identical(token, small_result$token), "\n")
  },
  error = function(e) {
    cat("✗ ERROR in small sample test:", e$message, "\n")
    stop("Small sample test failed - basic functionality is broken")
  }
)

# ============================================================================
# TEST 2: MEDIUM SAMPLE TO TEST TOKEN REFRESH
# ============================================================================

cat("\n=== TEST 2: Medium Sample (150 actors) ===\n")
cat("Testing token refresh mechanism with medium sample...\n")

token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

medium_actors <- sample(key_actors, 150)
cat("Selected", length(medium_actors), "actors for medium test\n")

tryCatch(
  {
    medium_result <- init_net(medium_actors, keywords, token, refresh_tok)
    cat("✓ init_net() succeeded with 150 actors\n")
    cat("  - Network size:", nrow(medium_result$net), "connections\n")
    cat("  - Unique actors:", n_distinct(medium_result$net$actor_handle), "\n")
    cat(
      "  - Unique follows:",
      n_distinct(medium_result$net$follows_handle),
      "\n"
    )
    cat("  - Token refreshed:", !identical(token, medium_result$token), "\n")
  },
  error = function(e) {
    cat("✗ ERROR in medium sample test:", e$message, "\n")
    cat("This suggests token refresh logic may have issues\n")
  }
)

# ============================================================================
# TEST 3: FULL SAMPLE TO REPRODUCE ORIGINAL ERROR
# ============================================================================

cat("\n=== TEST 3: Full Sample (", length(key_actors), " actors) ===\n")
cat("Testing with full sample that originally caused the error...\n")
cat(
  "This will take several minutes and test the periodic refresh every 100 actors\n"
)

token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Prompt for confirmation
cat(
  "Proceed with full test? This will process",
  length(key_actors),
  "actors (y/n): "
)
user_input <- readline()

if (tolower(substr(user_input, 1, 1)) == "y") {
  start_time <- Sys.time()

  tryCatch(
    {
      full_result <- init_net(key_actors, keywords, token, refresh_tok)
      end_time <- Sys.time()

      cat("✓ init_net() succeeded with ALL", length(key_actors), "actors!\n")
      cat(
        "  - Processing time:",
        round(difftime(end_time, start_time, units = "mins"), 2),
        "minutes\n"
      )
      cat("  - Network size:", nrow(full_result$net), "connections\n")
      cat("  - Unique actors:", n_distinct(full_result$net$actor_handle), "\n")
      cat(
        "  - Unique follows:",
        n_distinct(full_result$net$follows_handle),
        "\n"
      )
      cat("  - Token refreshed:", !identical(token, full_result$token), "\n")

      # Save result for potential use
      saveRDS(
        full_result,
        paste0(
          "../blueskyanalyses/data/test_init_net_result_",
          Sys.Date(),
          ".rds"
        )
      )
      cat("✓ Results saved to test_init_net_result_", Sys.Date(), ".rds\n")
    },
    error = function(e) {
      cat("✗ ERROR in full sample test:", e$message, "\n")
      cat("The token refresh fix may need further adjustment\n")
    }
  )
} else {
  cat("Skipping full test\n")
}

# ============================================================================
# TEST 4: BUILD_NETWORK INTEGRATION TEST
# ============================================================================

cat("\n=== TEST 4: build_network() Integration Test ===\n")
cat("Testing complete build_network() pipeline with updated init_net()...\n")

token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

# Use a smaller subset for the full pipeline test
pipeline_actors <- sample(key_actors, 20)

tryCatch(
  {
    pipeline_result <- build_network(
      key_actors = pipeline_actors,
      keywords = keywords,
      token = auth_object$accessJwt, # Fresh token
      refresh_tok = auth_object$refreshJwt,
      threshold = threshold,
      max_iterations = max_iterations,
      sample_size = 50, # Limit for testing
      prop = 1.0
    )

    cat("✓ build_network() pipeline succeeded!\n")
    cat("  - Final network size:", nrow(pipeline_result$net), "connections\n")
    cat("  - Profiles collected:", nrow(pipeline_result$profiles), "\n")
    cat("  - Widget created:", !is.null(pipeline_result$widget), "\n")
  },
  error = function(e) {
    cat("✗ ERROR in build_network() test:", e$message, "\n")
    cat("There may be integration issues with the updated init_net()\n")
  }
)

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n=== SUMMARY ===\n")
cat("Token refresh fix testing completed\n")
cat("Original error: 'Column `actor_handle` not found in `.data`'\n")
cat("Fix: Added periodic token refresh every 100 actors in init_net()\n")
cat("Status: Check test results above\n")
