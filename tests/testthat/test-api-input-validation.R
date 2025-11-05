# Test file for API wrapper input validation (no actual API calls)
library(testthat)
library(blueskynet)

test_that("get_token validates basic input formats", {
  # Test with clearly invalid handle formats (these should fail fast)
  expect_error(get_token("no_dot_handle", "password123"))
  expect_error(get_token("", "password123"))
  expect_error(get_token(NULL, "password123"))

  # Test with empty password
  expect_error(get_token("valid.bsky.social", ""))
  expect_error(get_token("valid.bsky.social", NULL))
})

test_that("verify_token handles basic input validation", {
  # Test with NULL - should error
  expect_error(verify_token(NULL))

  # Note: The current implementation may not validate token format strictly
  # but does require a non-NULL value
  expect_no_error(verify_token("any_string"))
})

test_that("refresh_token validates basic input", {
  expect_error(refresh_token(""))
  expect_error(refresh_token(NULL))
  expect_error(refresh_token("not_a_jwt"))
})

test_that("extract_follow_subjects processes records correctly", {
  # Create mock follow records (this doesn't require API calls)
  mock_records <- list(
    list(value = list(subject = "did:plc:user1")),
    list(value = list(subject = "did:plc:user2")),
    list(value = list(subject = "did:plc:user3"))
  )

  result <- extract_follow_subjects(mock_records)

  expect_type(result, "character")
  expect_length(result, 3)
  expect_true(all(grepl("^did:plc:", result)))
})

test_that("extract_follow_subjects handles empty records", {
  # Test with empty list
  result <- extract_follow_subjects(list())
  expect_length(result, 0)

  # The function should handle NULL gracefully
  expect_error(extract_follow_subjects(NULL))
})

test_that("find_follow_record finds correct record", {
  # Create mock follow records (no API calls needed)
  target_did <- "did:plc:target_user"
  mock_records <- list(
    list(value = list(subject = "did:plc:user1"), uri = "at://record1"),
    list(value = list(subject = target_did), uri = "at://record2"),
    list(value = list(subject = "did:plc:user3"), uri = "at://record3")
  )

  result <- find_follow_record(mock_records, target_did)

  expect_type(result, "list")
  expect_equal(result$value$subject, target_did)
  expect_equal(result$uri, "at://record2")
})

test_that("find_follow_record returns NULL for missing record", {
  mock_records <- list(
    list(value = list(subject = "did:plc:user1")),
    list(value = list(subject = "did:plc:user2"))
  )

  result <- find_follow_record(mock_records, "did:plc:missing_user")
  expect_null(result)
})