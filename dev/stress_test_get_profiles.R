library(tidyverse)
devtools::load_all("../blueskynet")

password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- Sys.getenv("BLUESKY_APP_USER")
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt

bignet <- readRDS("~/R-Projects/blueskyanalyses/data/research_big_net_2024-06-18.rds")
bigact <- bignet |> distinct(follows_handle) |> pull(follows_handle)

mini  <- bigact |> sample(5000)
small <- bigact |> sample(50000)

# Do we get identical results? Yes, for this mini and small sample
pr <- get_profiles(mini, token, refresh_tok)
pr_old <- get_profiles_old(mini, token)

pr <- get_profiles(small, token, refresh_tok)
pr_old <- get_profiles_old(small, token)

setdiff(pr$handle, pr_old$handle)

# How about the huge deal?
pr <- get_profiles(bigact, token, refresh_tok)

# By now, the original token might be stale
verify_token(token)
auth_object <- get_token(identifier, password)
token <- auth_object$accessJwt
refresh_tok <- auth_object$refreshJwt
verify_token(token)

pr_old <- get_profiles_old(bigact, token)
setdiff(pr$handle, pr_old$handle) |> length()
setdiff(pr_old$handle, pr$handle) |> length()

# Observations

# 14 handles are in the new implementation (we ran this first), but not in the old 
# 11 handles are in the old implementation (we ran this second), but not in the new
in_new <- setdiff(pr$handle, pr_old$handle) 
in_old <- setdiff(pr_old$handle, pr$handle) 

# Do we now, a few hours later, find the 11 handles that we miss, using the new function?
# Yes, they are there. But hang on a few mins later we find only 10 of the 11
pr1 <- get_profiles(in_old, token, refresh_tok)
pr1 |> nrow()
identical(pr1$handle, in_old)

# Sanity check: The old implementation now finds the same 10
pr2 <- get_profiles_old(in_old, token,)
pr2 |> nrow()
identical(pr2$handle, in_old)

# How about the 14 handles found by the new implementation, not the old? 
# Now we find two of those:
pr3 <- get_profiles_old(in_new, token)
pr3$handle

# Sanity check: Now we find only two of those handles again
pr4 <- get_profiles(in_new, token, refresh_tok)
pr4$handle

# Conclusions
# The two implementations find *almost* the same number of profiles given the
# long (453085) list of handles that we stored a few months ago. Discrepancies 
# vary a bit, so it's possible that handles gets deleted and protected/unprotected
# between runs.
# 
# It's a little puzzeling that *later* runs sometimes find *more* profiles; can
# it really be that some profiles get unprotected now and then?

# Anyway, we conclude that the two implementations are for all practical purposes
# identical

# Also, we noted that using a stale token results in: 
# Error message: HTTP 400 Bad Request.

# So the failure of  build_network() 