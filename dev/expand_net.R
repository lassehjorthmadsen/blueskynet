## notes for create_net() to iteratively build a network

expand_net <- function(network, keywords, token, follow_threshold = 1, max_iterations = 10) {

}


password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
my_did <- auth_object$did
threshold <- 20

net <- readRDS("dev/net/mkeyoung.bsky.social_2024-01-05_big.rds")

keywords <- read_csv(file = "dev/net/science_keywords.csv", col_names = F, col_types = "c")[[1]]
keywords <- paste(keywords, collapse = "|")

candidates <- net |>
  add_count(follows_handle) |>
  filter(!follows_handle %in% actor_handle, n > threshold) |>
  pull(follows_handle)

# Takes >15 min. for 114,646 handles (threshold = 1); too long
# Takes ~ 2 min. for 13,109 handles (threshold = 20); acceptable
# About a sec. for 100 handles, as a rule of thumb?
profiles <- get_profiles(candidates, token)

# How many of those seem to be in academia?
profiles2 <- profiles |>
  mutate(potential_researcher = str_detect(tolower(description), keywords))

profiles2 |> count(potential_researcher) # A clear majority

