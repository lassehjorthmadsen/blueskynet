# Test file for helper functions
library(testthat)
library(blueskynet)

test_that("word_freqs works correctly with basic text", {
  # Test basic functionality
  test_text <- c("hello world", "hello R programming", "world of data science")
  result <- word_freqs(test_text)

  # Should return a data frame
  expect_s3_class(result, "data.frame")

  # Should have the expected columns (from quanteda.textstats::textstat_frequency)
  expect_true(all(c("feature", "frequency") %in% names(result)))

  # Check that common words appear
  expect_true("hello" %in% result$feature)
  expect_true("world" %in% result$feature)

  # Check that frequency counts are correct
  hello_count <- result$frequency[result$feature == "hello"]
  expect_equal(hello_count, 2)
})

test_that("word_freqs handles empty input", {
  # Test with empty vector - should handle gracefully or error meaningfully
  expect_error(word_freqs(character(0)))

  # Test with NA values - quanteda handles this with warnings
  expect_warning(result <- word_freqs(c("hello", NA, "world")))
  expect_s3_class(result, "data.frame")
})

test_that("word_freqs handles special characters and punctuation", {
  test_text <- c("Hello, world!", "Data-science & machine-learning", "R/Python programming")
  result <- word_freqs(test_text)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)

  # Check that stopwords are removed
  expect_false("and" %in% result$feature)
  expect_false("the" %in% result$feature)
})

test_that("word_freqs respects the top parameter", {
  test_text <- c("apple banana cherry", "apple banana", "apple")
  result_all <- word_freqs(test_text, top = 100)  # Large number to get all words
  result_limited <- word_freqs(test_text, top = 2)

  expect_true(nrow(result_limited) <= 2)
  expect_true(nrow(result_all) >= nrow(result_limited))
})