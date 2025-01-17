% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/findMarkers.R
\name{findMarkers}
\alias{findMarkers}
\title{findMarkers}
\usage{
findMarkers(
  results,
  dataList,
  group,
  data.type = c("MH", "Metabolon", "Others"),
  species = c("hsa", "mmu"),
  p.value.cutoff = 0.05,
  auc.threshould = 0.6,
  fold.changes.cutoff = 1.5,
  nmarkers = 5,
  rank.plot = TRUE,
  dot.plot = TRUE,
  heatmap = TRUE
)
}
\arguments{
\item{results}{anova results obtained from normalizeDat.binary function}

\item{dataList}{raw data list of metabolome data}

\item{group}{grouping variable, need to be one variable}

\item{data.type}{select platform used, c("MH", "Metabolon", "Others")}

\item{species}{species to use "hsa" or "mmu"}

\item{p.value.cutoff}{p-value cutoff value}

\item{auc.threshould}{auc cutoff threshold}

\item{fold.changes.cutoff}{cutoff for fold changes cutoff, need ony higher cutoff.}

\item{nmarkers}{number of markers to select}

\item{rank.plot}{whether to plot rank plot}

\item{dot.plot}{whether to plot dot plot, only if more than 1 comparisons}

\item{heatmap}{whether to plot heatmap}
}
\value{
findMarkers analyses results in list object.
  The object contains the following:\itemize{
    \item raw.results all the results of roc analysis
    \item metabolite.rank.plot ranking plot
    \item dot.plot dot.plot of markers
    \item heatmap heatmap distribution of the markers
    \item marker.metabolites list of marker metabolites
  }
}
\description{
method to select classifer markers by AUC.
}
