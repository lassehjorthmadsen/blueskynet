% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrappers.R
\name{get_profiles}
\alias{get_profiles}
\title{Get profile for an actor/actors}
\usage{
get_profiles(actors, token, chunksize = 25)
}
\arguments{
\item{actors}{character, actor handle}

\item{token}{character, api token}

\item{chunksize}{integer, the number of actors per request;
defaults to 25, currently the maximum number allowed}
}
\value{
tibble with profiles
}
\description{
Get profile for an actor/actors
}
