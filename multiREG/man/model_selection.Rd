% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_selection.R
\name{model_selection}
\alias{model_selection}
\title{multiREG Model Selection}
\usage{
model_selection(x = NULL, y = NULL, selection_crit = NULL,
  alpha = NULL, penalty.factor = NULL)
}
\arguments{
\item{x}{Matrix of predictor variables.}

\item{y}{Vector of criterion variable.}

\item{selection_crit}{Model selection criteria (e.g., Bayesian information criterion, cross-validation).}

\item{alpha}{Elastic-net parameter.}

\item{penalty.factor}{User-set penalty matrix.}
}
\value{
Returns best model parameters based on fit indices.
}
\description{
multiREG Model Selection
}
\keyword{internal}
