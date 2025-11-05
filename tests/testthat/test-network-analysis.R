# Test file for network analysis functions
library(testthat)
library(blueskynet)
library(dplyr)

# Create sample network data for testing
create_sample_network <- function() {
  tibble::tibble(
    actor_handle = c("alice.bsky.social", "bob.bsky.social", "charlie.bsky.social",
                     "alice.bsky.social", "bob.bsky.social", "david.bsky.social"),
    follows_handle = c("bob.bsky.social", "charlie.bsky.social", "alice.bsky.social",
                       "charlie.bsky.social", "alice.bsky.social", "alice.bsky.social")
  )
}

create_sample_profiles <- function() {
  tibble::tibble(
    handle = c("alice.bsky.social", "bob.bsky.social", "charlie.bsky.social", "david.bsky.social"),
    displayName = c("Alice", "Bob", "Charlie", "David"),
    description = c("Data scientist working on ML", "Software engineer coding",
                   "ML researcher at university", "Data analyst and scientist"),
    followersCount = c(100, 150, 200, 80),
    community = c(1, 1, 2, 1),
    centrality = c(0.5, 0.3, 0.8, 0.2),
    pageRank = c(0.25, 0.20, 0.35, 0.20)
  )
}

test_that("trim_net removes low-follower nodes correctly", {
  sample_net <- create_sample_network()

  # Test with absolute threshold
  trimmed <- trim_net(sample_net, threshold = 2)

  expect_s3_class(trimmed, "data.frame")
  expect_true(all(c("actor_handle", "follows_handle") %in% names(trimmed)))

  # Should have fewer or equal rows than original
  expect_true(nrow(trimmed) <= nrow(sample_net))
})

test_that("trim_net handles proportional thresholds", {
  sample_net <- create_sample_network()

  # Test with proportional threshold
  trimmed <- trim_net(sample_net, threshold = 0.3)

  expect_s3_class(trimmed, "data.frame")
  expect_true(nrow(trimmed) <= nrow(sample_net))
})

test_that("trim_net handles empty networks", {
  empty_net <- tibble::tibble(actor_handle = character(0), follows_handle = character(0))

  result <- trim_net(empty_net, threshold = 1)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("com_labels generates appropriate labels", {
  sample_profiles <- create_sample_profiles()

  result <- com_labels(sample_profiles, top = 2)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("community", "community_label") %in% names(result)))

  # Should have one row per community
  expect_equal(nrow(result), length(unique(sample_profiles$community)))

  # Labels should be character strings
  expect_type(result$community_label, "character")

  # Each label should contain words separated by |
  expect_true(all(grepl("\\|", result$community_label) | nchar(result$community_label) > 0))
})

test_that("com_labels handles single community", {
  single_community <- tibble::tibble(
    community = c(1, 1, 1),
    description = c("data science", "machine learning", "data analysis")
  )

  result <- com_labels(single_community, top = 2)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$community, 1)
})

test_that("com_labels respects top parameter", {
  sample_profiles <- create_sample_profiles()

  result_top1 <- com_labels(sample_profiles, top = 1)
  result_top3 <- com_labels(sample_profiles, top = 3)

  # Both should have the same number of communities
  expect_equal(nrow(result_top1), nrow(result_top3))

  # Labels with top=3 should generally be longer (more words)
  avg_length_1 <- mean(nchar(result_top1$community_label))
  avg_length_3 <- mean(nchar(result_top3$community_label))
  expect_true(avg_length_3 >= avg_length_1)
})

test_that("add_metrics adds expected columns", {
  sample_net <- create_sample_network()
  sample_profiles <- create_sample_profiles()[1:3, ] # Only use profiles that exist in network

  # Remove the mock metrics columns for this test
  profiles_clean <- sample_profiles |> select(-community, -centrality, -pageRank)

  result <- add_metrics(profiles_clean, sample_net)

  expect_s3_class(result, "data.frame")

  # Should add the network metrics columns
  expected_cols <- c("centrality", "community", "pageRank", "insideFollowers", "community_label")
  expect_true(all(expected_cols %in% names(result)))

  # Should have the same number of rows as input profiles
  expect_equal(nrow(result), nrow(profiles_clean))
})

test_that("add_metrics handles NULL profiles", {
  sample_net <- create_sample_network()

  result <- add_metrics(NULL, sample_net)

  # Should still return something meaningful
  expect_true(!is.null(result))
})

test_that("create_widget produces a threejs object", {
  sample_net <- create_sample_network()
  sample_profiles <- create_sample_profiles()[1:3, ]

  skip_if_not_installed("threejs")

  result <- create_widget(sample_net, sample_profiles, prop = 1)

  # Should return a threejs htmlwidget
  expect_s3_class(result, "htmlwidget")
  expect_equal(result$package, "threejs")
})

test_that("create_widget handles sampling", {
  sample_net <- create_sample_network()
  sample_profiles <- create_sample_profiles()[1:3, ]

  skip_if_not_installed("threejs")

  # Test with smaller proportion
  result <- create_widget(sample_net, sample_profiles, prop = 0.5)

  expect_s3_class(result, "htmlwidget")
})