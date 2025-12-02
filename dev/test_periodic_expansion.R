# Test Periodic Network Expansion using Existing Functions
# Simple approach: sample actors from existing network and run build_network()

library(tidyverse)
devtools::load_all()

# ============================================================================
# SETUP
# ============================================================================

cat("=== PERIODIC EXPANSION TEST ===\n")

# Authentication
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")

if (password == "" || identifier == "") {
  stop("Please set BLUESKY_APP_PASS and BLUESKY_APP_USER environment variables")
}

auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt
cat("✓ Authentication successful\n")

# Load existing network data
cat("Loading existing network...\n")
existing_net <- read_rds("../blueskyanalyses/data/research_net_2025-11-18.rds")
keywords <- read_lines("../blueskyanalyses/data/research_keywords.txt")

cat("✓ Loaded existing network:\n")
cat("  - Network connections:", nrow(existing_net), "\n")
cat("  - Unique actors:", n_distinct(existing_net$actor_handle), "\n")
cat("  - Unique follows:", n_distinct(existing_net$follows_handle), "\n")
cat("  - Keywords:", length(keywords), "\n")

# ============================================================================
# PERIODIC EXPANSION STRATEGY
# ============================================================================

perform_periodic_expansion <- function(
  existing_net,
  keywords,
  token,
  refresh_tok,
  sample_size = 50,
  max_iterations = 1,
  expansion_sample_size = 200,
  threshold = 0.01
) {
  cat("\n=== Starting Periodic Expansion ===\n")
  start_time <- Sys.time()

  # Sample actors from existing network
  all_actors <- unique(existing_net$actor_handle)
  cat(
    "Sampling",
    sample_size,
    "actors from",
    length(all_actors),
    "total actors\n"
  )

  if (length(all_actors) < sample_size) {
    sampled_actors <- all_actors
    cat(
      "Warning: Using all",
      length(all_actors),
      "actors (less than requested sample size)\n"
    )
  } else {
    sampled_actors <- sample(all_actors, sample_size)
  }

  cat("Selected actors for expansion:\n")
  cat(paste("  -", head(sampled_actors, 5), collapse = "\n"), "\n")
  if (length(sampled_actors) > 5) {
    cat("  - ... and", length(sampled_actors) - 5, "more\n")
  }

  # Run existing build_network pipeline on sampled actors
  cat("\nRunning build_network() on sampled actors...\n")
  expansion_result <- build_network(
    key_actors = sampled_actors,
    keywords = keywords,
    token = token,
    refresh_tok = refresh_tok,
    threshold = threshold,
    prop = 0, # Skip widget creation for speed
    max_iterations = max_iterations,
    sample_size = expansion_sample_size,
    save_net = FALSE # Don't save intermediate results
  )

  # Merge results with existing network
  cat("\nMerging with existing network...\n")
  original_size <- nrow(existing_net)
  expansion_size <- nrow(expansion_result$net)

  merged_net <- bind_rows(existing_net, expansion_result$net) %>%
    distinct()

  final_size <- nrow(merged_net)
  net_growth <- final_size - original_size

  end_time <- Sys.time()
  runtime <- difftime(end_time, start_time, units = "mins")

  # Summary
  cat("\n=== Expansion Complete ===\n")
  cat("Runtime:", round(as.numeric(runtime), 2), "minutes\n")
  cat("Actors sampled:", length(sampled_actors), "\n")
  cat("Original network size:", original_size, "connections\n")
  cat("Expansion found:", expansion_size, "connections\n")
  cat("After merging:", final_size, "connections\n")
  cat("Net growth:", net_growth, "new connections\n")
  cat("Growth rate:", round(net_growth / original_size * 100, 2), "%\n")

  return(list(
    merged_net = merged_net,
    expansion_result = expansion_result,
    summary = list(
      runtime_minutes = as.numeric(runtime),
      actors_sampled = length(sampled_actors),
      original_size = original_size,
      expansion_size = expansion_size,
      final_size = final_size,
      net_growth = net_growth,
      growth_rate = net_growth / original_size
    )
  ))
}

# ============================================================================
# TEST 1: Small Sample (Quick Test)
# ============================================================================

cat("\n=== TEST 1: Small Sample (10 actors) ===\n")
cat("Quick test to verify the approach works...\n")

small_test <- perform_periodic_expansion(
  existing_net = existing_net,
  keywords = keywords,
  token = token,
  refresh_tok = refresh_tok,
  sample_size = 10,
  max_iterations = 2,
  expansion_sample_size = 50,
  threshold = 2
)

# ============================================================================
# TEST 2: Medium Sample (Realistic Test)
# ============================================================================

token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

cat("\n=== TEST 2: Medium Sample (50 actors) ===\n")
cat("More realistic test for periodic expansion...\n")

# Ask user if they want to proceed
cat("This will take 15-30 minutes. Proceed? (y/n): ")
user_input <- readline()

if (tolower(substr(user_input, 1, 1)) == "y") {
  medium_test <- perform_periodic_expansion(
    existing_net = existing_net,
    keywords = keywords,
    token = token,
    refresh_tok = refresh_tok,
    sample_size = 50,
    max_iterations = 1,
    expansion_sample_size = 200,
    threshold = 0.01
  )

  # Save results
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  result_file <- paste0(
    "../blueskyanalyses/data/periodic_expansion_",
    timestamp,
    ".rds"
  )
  saveRDS(medium_test, result_file)
  cat("✓ Results saved to:", result_file, "\n")
} else {
  cat("Skipping medium test\n")
}

# ============================================================================
# SIMULATION: Multiple Periodic Updates
# ============================================================================

simulate_periodic_updates <- function(
  existing_net,
  keywords,
  token,
  refresh_tok,
  n_periods = 3,
  sample_size = 25
) {
  cat("\n=== SIMULATING", n_periods, "PERIODIC UPDATES ===\n")

  current_net <- existing_net
  all_summaries <- list()

  for (period in 1:n_periods) {
    cat("\n--- Period", period, "---\n")

    # Run expansion
    result <- perform_periodic_expansion(
      existing_net = current_net,
      keywords = keywords,
      token = token,
      refresh_tok = refresh_tok,
      sample_size = sample_size,
      max_iterations = 2,
      expansion_sample_size = 100,
      threshold = 2
    )

    # Update for next iteration
    current_net <- result$merged_net
    token <- result$expansion_result$token
    refresh_tok <- result$expansion_result$refresh_tok
    all_summaries[[period]] <- result$summary

    cat(
      "Cumulative network size after period",
      period,
      ":",
      nrow(current_net),
      "\n"
    )
  }

  # Summary of all periods
  cat("\n=== SIMULATION SUMMARY ===\n")
  total_runtime <- sum(sapply(all_summaries, function(x) x$runtime_minutes))
  total_growth <- nrow(current_net) - nrow(existing_net)

  cat("Total runtime:", round(total_runtime, 2), "minutes\n")
  cat("Original network:", nrow(existing_net), "connections\n")
  cat("Final network:", nrow(current_net), "connections\n")
  cat("Total growth:", total_growth, "connections\n")
  cat("Average growth per period:", round(total_growth / n_periods, 1), "\n")

  return(list(
    final_net = current_net,
    period_summaries = all_summaries
  ))
}

cat("\n=== TEST 3: Simulate Multiple Updates ===\n")
cat("Simulate running periodic updates over time (small scale)...\n")
cat("This will run 3 mini-expansions with 25 actors each.\n")
cat("Proceed? (y/n): ")

user_input <- readline()
if (tolower(substr(user_input, 1, 1)) == "y") {
  simulation <- simulate_periodic_updates(
    existing_net = existing_net,
    keywords = keywords,
    token = auth_object$accessJwt,
    refresh_tok = auth_object$refreshJwt,
    n_periods = 3,
    sample_size = 25
  )
}

cat("\n=== ALL TESTS COMPLETE ===\n")
cat("Strategy: Use existing build_network() with random sampling\n")
cat("Advantage: Simple, uses tested code, configurable runtime\n")
cat("For production: Sample 50-100 actors, run weekly/daily\n")
