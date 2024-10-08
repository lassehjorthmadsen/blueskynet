###################################################
# Demo how to use wrapper functions in blueskynet #
###################################################

library(tidyverse)
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
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
my_did <- auth_object$did
refresh_tok <- auth_object$refreshJwt

# Get all follows for an actor
actor <- "mkeyoung.bsky.social"
follows <- get_follows(actor, token)

# Get profile information for a single actors
profile <- get_profiles(actor, token)

# Get profile information for many actors
actors <- follows$handle
profiles <- get_profiles(actors, token)

# Follow Mike
actor_did <- get_profiles("mkeyoung.bsky.social", token)$did
resp <- follow_actor(my_did = my_did, actor_did = actor_did, token = token)

# Follow Neil Gaiman
neil_did <- get_profiles("neilhimself.neilgaiman.com", token)$did
resp <- follow_actor(my_did = my_did, actor_did = neil_did, token = token)

# Follow many actors
dids <- follows |> slice_sample(n = 5) |> pull(did)
resps <- dids |> map(\(x) follow_actor(my_did = my_did, actor_did = x, token = token))

# Follow all Mike's follows
dids <- follows |> pull(did)
resps <- dids |> map(\(x) follow_actor(my_did = my_did, actor_did = x, token = token))

# Check an actor that caused my script to break, hmm appears to work?
actor <- "drfingerstyle.bsky.social"
profile <- get_profiles(actor, token)
follows <- get_follows(actor, token)
