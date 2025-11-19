# Calculate word frequencies from text data

Analyzes a collection of texts (such as user profile descriptions) to
identify the most frequently used words or word pairs (bigrams). Useful
for understanding the common themes and topics within network
communities.

## Usage

``` r
word_freqs(
  texts,
  bigrams = FALSE,
  top = 30,
  remove_stopwords = TRUE,
  language = "en"
)
```

## Arguments

- texts:

  Character vector. Texts to analyze (e.g., user profile descriptions)

- bigrams:

  Logical. If TRUE, count word pairs instead of individual words
  (default FALSE)

- top:

  Integer. Number of top frequent words/bigrams to return (default 30)

- remove_stopwords:

  Logical. Remove common stopwords like "the", "and" (default TRUE)

- language:

  Character. Language for stopword removal (default "en" for English)

## Value

A data frame with word frequency statistics:

- feature:

  Character. The word or bigram

- frequency:

  Integer. Number of occurrences

- rank:

  Integer. Rank by frequency (1 = most frequent)

- docfreq:

  Integer. Number of documents containing the feature

- group:

  Character. Always "all" for this function

## See also

[`com_labels`](https://lassehjorthmadsen.github.io/blueskynet/reference/com_labels.md)

## Examples

``` r
# Sample user descriptions
descriptions <- c(
  "Data scientist working on machine learning projects",
  "Climate researcher studying global warming effects",
  "Marine biologist researching ocean ecosystems",
  "Environmental data scientist analyzing climate patterns"
)

# Get top words
word_freq <- word_freqs(descriptions, top = 10)
head(word_freq)
#>     feature frequency rank docfreq group
#> 1      data         2    1       2   all
#> 2 scientist         2    1       2   all
#> 3   climate         2    1       2   all
#> 4   working         1    4       1   all
#> 5   machine         1    4       1   all
#> 6  learning         1    4       1   all

# Get top bigrams
bigram_freq <- word_freqs(descriptions, bigrams = TRUE, top = 5)
head(bigram_freq)
#>             feature frequency rank docfreq group
#> 1    data scientist         2    1       2   all
#> 2 scientist working         1    2       1   all
#> 3   working machine         1    2       1   all
#> 4  machine learning         1    2       1   all
#> 5 learning projects         1    2       1   all

if (FALSE) { # \dontrun{
# With real profile data from network analysis
auth <- get_token("your.handle.bsky.social", "your-app-password")
profiles <- get_profiles(c("user1.bsky.social", "user2.bsky.social"), auth$accessJwt)
word_analysis <- word_freqs(profiles$description, top = 50)
} # }
```
