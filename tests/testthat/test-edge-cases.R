# Test file for edge cases and error handling
library(testthat)
library(blueskynet)

test_that("functions handle malformed input gracefully", {
  # Test functions with various malformed inputs

  # word_freqs with weird inputs
  expect_error(word_freqs(list("not a character vector")))
  expect_no_error(word_freqs(c("normal text", "", "   ", NA)))

  # Network functions with malformed data
  bad_network <- data.frame(
    wrong_column = c("a", "b"),
    another_wrong = c("c", "d")
  )

  expect_error(trim_net(bad_network, threshold = 1))
})

test_that("functions handle very large inputs appropriately", {
  skip_on_cran()

  # Test word_freqs with large text
  large_text <- rep("word", 10000)
  result <- word_freqs(large_text, top = 10)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) <= 10)

  # Test network functions with larger networks
  large_network <- tibble::tibble(
    actor_handle = rep(paste0("user", 1:100, ".bsky.social"), each = 10),
    follows_handle = rep(paste0("user", 1:100, ".bsky.social"), times = 10)
  )

  expect_no_error(trim_net(large_network, threshold = 2))
})

test_that("functions handle Unicode and international text", {
  unicode_text <- c("café résumé", "naïve Zürich", "東京 москва", "🚀🎉📊")

  result <- word_freqs(unicode_text)
  expect_s3_class(result, "data.frame")

  # Test with profiles containing Unicode
  unicode_profiles <- tibble::tibble(
    community = c(1, 1, 2, 2),
    description = c("café scientist 📊", "résumé data análisis",
                   "東京 researcher ML", "москва developer AI")
  )

  expect_no_error(com_labels(unicode_profiles, top = 2))
})

test_that("functions validate data types correctly", {
  # Test with wrong data types
  expect_error(word_freqs(123))
  expect_error(word_freqs(c(1, 2, 3)))

  # Test trim_net with non-tibble input (should error)
  list_input <- list(
    actor_handle = c("a", "b"),
    follows_handle = c("c", "d")
  )
  expect_error(trim_net(list_input, threshold = 1))

  # Test com_labels with missing columns
  incomplete_profiles <- tibble::tibble(
    community = c(1, 2),
    wrong_column = c("text1", "text2")
  )
  expect_error(com_labels(incomplete_profiles))
})

test_that("network functions handle disconnected graphs", {
  # Create a network with isolated components
  disconnected_net <- tibble::tibble(
    actor_handle = c("group1a.bsky.social", "group1b.bsky.social",
                    "group2a.bsky.social", "group2b.bsky.social"),
    follows_handle = c("group1b.bsky.social", "group1a.bsky.social",
                      "group2b.bsky.social", "group2a.bsky.social")
  )

  # Should still work with disconnected components
  expect_no_error(trim_net(disconnected_net, threshold = 1))

  profiles <- tibble::tibble(
    handle = c("group1a.bsky.social", "group1b.bsky.social",
              "group2a.bsky.social", "group2b.bsky.social"),
    displayName = c("User 1A", "User 1B", "User 2A", "User 2B"),
    description = c("Group one member", "Group one leader",
                   "Group two member", "Group two leader")
  )

  expect_no_error(add_metrics(profiles, disconnected_net))
})

test_that("functions handle duplicate data appropriately", {
  # Test network with duplicate edges
  duplicate_net <- tibble::tibble(
    actor_handle = c("a.bsky.social", "a.bsky.social", "b.bsky.social"),
    follows_handle = c("b.bsky.social", "b.bsky.social", "a.bsky.social")
  )

  result <- trim_net(duplicate_net, threshold = 1)
  expect_s3_class(result, "data.frame")

  # Should remove duplicates
  expect_true(nrow(result) <= nrow(duplicate_net))
})

test_that("performance is reasonable for medium-sized data", {
  skip_on_cran()

  # Create medium-sized test data
  n_users <- 500
  n_connections <- 2000

  medium_network <- tibble::tibble(
    actor_handle = sample(paste0("user", 1:n_users, ".bsky.social"), n_connections, replace = TRUE),
    follows_handle = sample(paste0("user", 1:n_users, ".bsky.social"), n_connections, replace = TRUE)
  )

  # Should complete within reasonable time
  start_time <- Sys.time()
  result <- trim_net(medium_network, threshold = 2)
  end_time <- Sys.time()

  expect_true(difftime(end_time, start_time, units = "secs") < 30) # Should take less than 30 seconds
  expect_s3_class(result, "data.frame")
})