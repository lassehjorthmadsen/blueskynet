% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/algos.R
\name{trim_net}
\alias{trim_net}
\title{Trim network}
\usage{
trim_net(net, threshold)
}
\arguments{
\item{net}{tibble with network connections (edges). Assumed to contain two columns:
\code{actor_handle} (the Blue Sky Social actor who is followING another) and \code{follows_handle}
(the actor being followed).}

\item{threshold}{the threshold for including actors in the expansion: How many
followers must a prospect have, to be considered? If smaller than 1, threshold is used
as a proportion: How big a proportion must a prospect have, to be considered?}
}
\value{
tibble with the expanded network
}
\description{
Iteratively trims a network so that the set of actors and the set of follows are identical.
Also excludes rows with NA in either actors or follows columns or invalid handle. Finally,
excludes actors with less that a certain number of followers within the network.
}
