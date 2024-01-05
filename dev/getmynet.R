###################################################
# Demo how to get network from Mike's follows     #
###################################################

library(tidygraph)
library(igraph)
library(tidyverse)
library(RColorBrewer)
devtools::load_all()

# In case we just want to work with already saved data:
net <- readRDS("~/R-Projects/blueskynet/dev/net/mkeyoung.bsky.social_2024-01-05_big.rds")
profiles <- read_delim("dev/net/profiles_2024-01-05.csv", delim = ";", escape_double = FALSE, trim_ws = TRUE)

# For generating new data:
password <- Sys.getenv("BLUESKY_APP_PASS")
identifier <- "lassehjorthmadsen.bsky.social"

token <- get_token(identifier, password)

path <- "dev/net/" # The collected networks goes here

# Get all follows for an actor
actor <- "mkeyoung.bsky.social"
follows <- get_follows(actor, token)

# Get follows of follows -- the network that we want
netmembers <- follows$handle |> as.list() |> set_names()

net <- netmembers |>
  map_dfr(get_follows, token, .id = "actor_handle") |>
  select(actor_handle, follows_handle = handle)

# Save the big net (for finding potential new members)
file_name <- paste0(path, actor, "_", Sys.Date(), "_big.rds")
net |> saveRDS(file = file_name)

# Save the small net
file_name <- paste0(path, actor, "_", Sys.Date(), ".rds")
net |> filter(follows_handle %in% actor_handle) |> saveRDS(file = file_name)

# Get profiles for all actors in net
actors <- c(net$actor_handle, net$follows_handle) |> unique()
profiles <- get_profiles(actors, token)

# Save profiles
file_name <- paste0(path, "profiles", "_", Sys.Date(), ".csv")
profiles |> write_csv2(file_name)

# Compute centrality and page rank
file_name <- paste0(path, "network", "_", Sys.Date(), ".csv")

# graph object
graph <- net |>
  filter(follows_handle %in% actor_handle) |>
  as_tbl_graph() |>
  activate(nodes)

# compute centrality
centrality <- centr_betw(graph)
V(graph)$centrality <- centrality$res

# Identify high density subgraphs, "communities"
community <- cluster_walktrap(graph)
V(graph)$community <- community$membership

# compute page rank
prank <- page.rank(graph)
V(graph)$page_rank <- prank$vector

# Join and save
graph |>
  as_tibble() |>
  rename(handle = name) |>
  inner_join(profiles, by = "handle") |>
  select(-avatar, - banner, -did) |>
  write_csv(file = file_name)

# Create graph widget
edges <- graph |> activate(edges) |> as_tibble()
nodes <- graph  |> activate(nodes) |> mutate(id = row_number()) |> as_tibble()

# Make colors based on communities
community_cols <- 3 %>% brewer.pal("Set1") %>% colorRampPalette()
use_colors <- n_distinct(nodes$com_label) %>% community_cols() %>% sample()

nodes <- nodes %>%
  mutate(com_label = fct_infreq(as.character(community)),
         com_label = fct_lump(com_label, n = 10)) %>%
  group_by(com_label) %>%
  mutate(n = n(), com_id = cur_group_id()) %>%
  ungroup() %>%
  mutate(com_label = ifelse(com_id == max(com_id), "Other",
                            paste0(LETTERS[com_id], ", n=", n)))

nodes <- nodes %>%
  mutate(color = use_colors[com_id],
         groupname = com_label)


# Check out other packages
# 3d with threejs
widget1 <- graphjs(graph, bg = "black", vertex.size = 0.2, edge.width = .3,
                   edge.alpha = .3, vertex.color = nodes$color, vertex.label = paste(nodes$user_name, nodes$bio, sep = ": "))

saveWidget(widget1, file = "Institutions.html")
# browseURL("Wollongong_graph.html")


# Create dataset with candidates for inclusion in net, i.e. actors *outside* the net
# followed by actors *inside* the net
file_name <- paste0(path, "candidates", "_", Sys.Date(), ".csv")

# Keywords indicative of researchers:
keywords <- read_csv(file = "dev/net/science_keywords.csv", col_names = F, col_types = "c")[[1]]
keywords <- paste(keywords, collapse = "|")

candidates <- net %>%
  filter(!follows_handle %in% actor_handle) %>%
  count(follows_handle, name = "followers_in_net") |>
  filter(followers_in_net > 2) |>
  left_join(profiles, by = c("follows_handle" = "handle")) |>
  select(-avatar, - banner, -did) |>
  mutate(potential_researcher = str_detect(tolower(description), keywords)) |>
  arrange(-potential_researcher, -followers_in_net)

candidates |>  write_csv(file = file_name)
