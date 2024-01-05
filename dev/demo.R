###################################################
# Demo how to use wrapper functions in blueskynet #
###################################################

devtools::load_all()

# Create an app password here: https://bsky.app/settings/app-passwords
# then set environment variable BLUESKY_APP_PASS to your app password
# using file.edit("~/.Renviron")

# Now get the app password like this:
password <- Sys.getenv("BLUESKY_APP_PASS")

# Or, alternatively, store it in a file outside the project:
password <- readLines("c:/Users/LMDN/blueskynet_secrets/app_password.txt")

# Set identifier (not a secret)
identifier <- "lassehjorthmadsen.bsky.social"

# Or use an environment variable again:
identifier <- Sys.getenv("BLUESKY_APP_USER")

# Use identifier and password to get a token:
token <- get_token(identifier, password)

# Get all follows for an actor
actor <- "mkeyoung.bsky.social"
follows <- get_follows(actor, token)

# Get profile information for a single actors
profile <- get_profiles(actor, token)

# Get profile information for many actors
actors <- follows$handle
profiles <- get_profiles(actors, token)
