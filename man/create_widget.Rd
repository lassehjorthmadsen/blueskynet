% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/algos.R
\name{create_widget}
\alias{create_widget}
\title{Create a 3d-widget}
\usage{
create_widget(net, profiles, prop = 1)
}
\arguments{
\item{net}{tibble with two columns, two columns: \code{actor_handle}
(the Blue Sky actor who is followING another) and \code{follows_handle}
(the actor being followed).}

\item{profiles}{tibble with list of actors in net}

\item{prop}{proportion of the actors sampled for visualization}
}
\value{
html widget
}
\description{
Create a 3d-widget
}
