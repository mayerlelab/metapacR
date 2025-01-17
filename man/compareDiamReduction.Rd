% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compareDiamReduction.R
\name{compareDiamReduction}
\alias{compareDiamReduction}
\title{compareDiamReduction}
\usage{
compareDiamReduction(dataList, plotting.variable = NULL, crossvalI = 7)
}
\arguments{
\item{dataList}{raw metabolome data list from imputeTransformScale function.It need to have imputed.matrix and metadata.}

\item{plotting.variable}{plotting grouping variable..should be 1}

\item{crossvalI}{number of cross-validation segments}
}
\value{
Multivariate analyses results in list object.
  The object contains the following:\itemize{
    \item plot comparative diamemtionality reduction plot
    \item pca S4 object of pca results
    \item opls S4 object of opls results
    \item rtsne S4 object of tsne results
    \item rtsme.pca S4 object of tsne + pca results
    \item kmeans S4 object of kmeans results
    \item umap S4 object of umap results
  }
}
\description{
function to compare different diamentionality reduction methods, namely, PCA, OPLS, TSNE and UMAP.
}
