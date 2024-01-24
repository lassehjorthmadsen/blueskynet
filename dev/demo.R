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

# Get all follows for an actor
actor <- "mkeyoung.bsky.social"
follows <- get_follows(actor, token)

# Get profile information for a single actors
profile <- get_profiles(actor, token)

# Get profile information for many actors
actors <- follows$handle
profiles <- get_profiles(actors, token)

# Follow some actor
actor_did <- get_profiles("mkeyoung.bsky.social", token)$did
resp <- follow_actor(my_did = my_did, actor_did = actor_did, token = token)

# Follow many actors
fol_smp <- follows |> slice_sample(n = 5)
actors_did <- fol_smp$did

# Why won't this work?
resps <- actors_did |> map(\(x) follow_actor(my_did = my_did, actor_did = x, token = token))

# Or this?
random_actor <- actors_did |> sample(1)
resp <- follow_actor(my_did = my_did, actor_did = random_actor, token = token)

# This?
neil_did <- get_profiles("neilhimself.neilgaiman.com", token)$did
resp <- follow_actor(my_did = my_did, actor_did = neil_did, token = token)
