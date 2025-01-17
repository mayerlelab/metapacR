#' @title enrichedNetwork
#'
#' @description plot enriched annotated netwroks for the signficantly altered metabolic pathways.
#'
#' @param species species to use "hsa" or "mmu"
#' @param ref.path saving path
#' @param results fold changes results
#' @param p.value.cutoff cutoff value of p.value
#' @param data.type  select platform used, c("MH", "Metabolon", "Others")
#' @param fold.changes.cutoff higher cutoff value of fold changes
#' @param network.method "diffusion" as method of choice, for other method refer to FELLA. CUrrently only caliberated for diffusion.
#' @param legend.pathway number of pathways to map on plot
#' @param save either "pdf", "svg", "png" or "none"
#' @param fig.width plot width not applicable for pdf
#' @param fig.height plot height not applicable for pdf
#' @param Other_metadata dataframe with metadata....it must have  columns: Metabolite, Metabolite_Name, Ontology_Class, Ontology_Subclass.
#, KEGG
#'
#' @import tidyverse
#' @importFrom here here
#' @importFrom ggrepel geom_text_repel
#' @importFrom RColorBrewer brewer.pal
#' @import graphics
#' @import grDevices
#' @importFrom sjPlot save_plot
#' @importFrom KEGGREST keggLink
#' @importFrom org.Hs.eg.db org.Hs.egSYMBOL2EG
#' @importFrom org.Mm.eg.db org.Mm.egSYMBOL2EG
#' @import stats
#' @importFrom FELLA buildGraphFromKEGGREST buildDataFromGraph loadKEGGdata getCom enrich generateResultsGraph getPscores generateResultsTable
#' @import igraph
#' @importFrom scales squish
#'
#' @return results of enrichment network and network plots as save object in defined path.
#' The object contains the following:\itemize{
#'     \item results enrichment results
#'     \item plot.pathway.impact list of all the plots of pathway.impact
#'   }
#'
#' @export

enrichedNetwork <- function(results,
                            species = c("hsa", "mmu"),
                            ref.path = NULL,
                            p.value.cutoff = 0.05,
                            fold.changes.cutoff = 1.5,
                            network.method = "diffusion",
                            legend.pathway = 3,
                            save = c("pdf", "svg", "png", "none"),
                            data.type = c("MH", "Metabolon", "Others"),
                            fig.width = 12,
                            fig.height = 9,
                            Other_metadata = NULL) {
  stopifnot(inherits(results, "data.frame"))
  validObject(results)

  species <- match.arg(species,c("hsa", "mmu"))
  save <- match.arg(save, c("pdf", "svg", "png", "none"))
  data.type <- match.arg(data.type, c("MH", "Metabolon", "Others"))

  enrichment.results <- data.frame()

  plot.pathway.impact <- list()

  if (is.null(ref.path)) {
    ref.path <- here::here()
    ifelse(!dir.exists(file.path(paste0(ref.path), "results")),
           dir.create(file.path(paste0(ref.path), "results")),
           FALSE
    )
    path <- paste(ref.path, "results", sep = "/")
  } else {
    ref.path <- ref.path
  }

  if (data.type == "Others") {
    stopifnot(inherits(Other_metadata, "data.frame"))
    validObject(Other_metadata)
  }

  ## load annotation file
  if (data.type == "Metabolon" && species %in% c("hsa", "mmu")) {
    data("chemicalMetadata")
    chemicalMetadata <- force(chemicalMetadata)

    chemicalMetadata <- chemicalMetadata %>%
      mutate(across(everything(), as.character))

    ## define metabolite classes
    columnToSelect <- c("SUPER_PATHWAY", "CHEMICAL_NAME", "KEGG", "MET_CHEM_NO")
    metabolite_class <- chemicalMetadata %>%
      dplyr::select(any_of(columnToSelect)) %>%
      separate_rows(KEGG, sep=",") %>%
      mutate(KEGG=trimws(KEGG))

    ## load enriched data
    pathDat <- results %>%
      dplyr::filter(adj.P.Val < p.value.cutoff) %>%
      left_join(metabolite_class, by = c("Metabolite" = "MET_CHEM_NO")) %>%
      dplyr::rename(keggID =KEGG) %>%
      drop_na(keggID)
  }

  if (data.type == "MH" && species == "hsa") {
    data("chemicalMetadata_MH")
    chemicalMetadata <- force(chemicalMetadata_MH)

    chemicalMetadata <- chemicalMetadata %>%
      mutate(across(everything(), as.character))

    ## define metabolite classes
    columnToSelect <- c("ONTOLOGY1_NAME", "METABOLITE_NAME", "KEGG", "MET_CHEM_NO")
    metabolite_class <- chemicalMetadata %>%
      dplyr::select(any_of(columnToSelect)) %>%
      separate_rows(KEGG, sep=",") %>%
      mutate(KEGG=trimws(KEGG))

    ## load enriched data
    pathDat <- results %>%
      dplyr::filter(adj.P.Val < p.value.cutoff) %>%
      left_join(metabolite_class, by = c("Metabolite" = "MET_CHEM_NO")) %>%
      dplyr::rename(keggID =KEGG) %>%
      drop_na(keggID)
  }

  if (data.type == "MH" && species == "mmu") {
    data("chemicalMetadata_MH_mmu")
    chemicalMetadata <- force(chemicalMetadata_MH_mmu)

    chemicalMetadata <- chemicalMetadata %>%
      mutate(across(everything(), as.character))

    ## define metabolite classes
    columnToSelect <- c("ONTOLOGY1_NAME", "METABOLITE_NAME", "KEGG_ID", "MET_CHEM_NO")
    metabolite_class <- chemicalMetadata %>%
      dplyr::select(any_of(columnToSelect)) %>%
      mutate(KEGG = KEGG_ID) %>%
      dplyr::select(-KEGG_ID) %>%
      separate_rows(KEGG, sep=",") %>%
      mutate(KEGG=trimws(KEGG))

    ## load enriched data
    pathDat <- results %>%
      dplyr::filter(adj.P.Val < p.value.cutoff) %>%
      left_join(metabolite_class, by = c("Metabolite" = "MET_CHEM_NO")) %>%
      dplyr::rename(keggID =KEGG) %>%
      drop_na(keggID)
  }

  if (data.type == "Others") {
    chemicalMetadata <- Other_metadata

    chemicalMetadata <- chemicalMetadata %>%
      mutate(across(everything(), as.character))

    columnToSelect <- c("Metabolite", "Metabolite_Name", "Ontology_Class", "Ontology_Subclass", "KEGG")
    metabolite_class <- chemicalMetadata %>%
      dplyr::select(any_of(columnToSelect)) %>%
      rename(c(
        "MET_CHEM_NO" = "Metabolite",
        "METABOLITE_NAME" = "Metabolite_Name",
        "ONTOLOGY1_NAME" = "Ontology_Class"
      )) %>%
      separate_rows(KEGG, sep=",") %>%
      mutate(KEGG=trimws(KEGG))

    ## load enriched data
    pathDat <- results %>%
      dplyr::filter(adj.P.Val < p.value.cutoff) %>%
      left_join(metabolite_class, by = c("Metabolite" = "MET_CHEM_NO")) %>%
      dplyr::rename(keggID =KEGG) %>%
      drop_na(keggID)
  }

  ## define direction
  pathDat$direction <- ifelse(log2(pathDat$logFC) > fold.changes.cutoff, "up",
                              ifelse(log2(pathDat$logFC) < -fold.changes.cutoff, "down",
                                     "nochange"
                              )
  )

  ## identify reference pathways wrt species
  keggTest <- KEGGREST::keggLink("pathway", unique(pathDat$keggID))
  keggTest <- data.frame(keggID=names(keggTest), keggPath=keggTest, row.names = NULL)
  keggTest$keggID <- gsub("^.*?:", "", keggTest$keggID)
  keggTest$keggPath <- gsub("path:map", "", keggTest$keggPath)

  # identify reference pathways wrt species
  keggRef <- KEGGREST::keggLink("pathway", species)
  keggRef <- data.frame(geneID=names(keggRef), keggPath=keggRef, row.names = NULL)
  # rownamesRef <- names(keggRef)  ## gene ID
  keggRef$keggPath <- gsub(paste0("path:", species), "", keggRef$keggPath)

  ## create pathway fella data
  pathDatFella <- keggRef %>%
    inner_join(keggTest, by ="keggPath") %>%
    inner_join(pathDat, by = "keggID") %>%
    drop_na(contrast)


  ## filter overview pathways
  graph <- FELLA::buildGraphFromKEGGREST(
    organism = species,
    filter.path = NULL
  )

  ## Cannot be overwritten
  tmpdir <- paste0(tempdir())
  unlink(tmpdir, recursive = TRUE)

  ## build data from graph
  FELLA::buildDataFromGraph(
    keggdata.graph = graph,
    databaseDir = tmpdir,
    internalDir = FALSE,
    matrices = network.method,
    normality = "diffusion",
    niter = 250
  )
  if (species == "hsa") {
    alias2entrez <- as.list(org.Hs.eg.db::org.Hs.egSYMBOL2EG)
  } else if (species == "mmu") {
    alias2entrez <- as.list(org.Mm.eg.db::org.Mm.egSYMBOL2EG)
  }

  ## get associated pathways
  entrez2ec <- KEGGREST::keggLink("enzyme", species)
  entrez2path <- KEGGREST::keggLink("pathway", species)

  ## perform FELLA
  fellaData <- FELLA::loadKEGGdata(
    databaseDir = tmpdir,
    internalDir = FALSE,
    loadMatrix = network.method
  )

  ## get FELLA community

  ## compound
  idCpd <- FELLA::getCom(fellaData,
                         level = 5,
                         format = "id"
  ) %>% names()
  ## reaction
  idRx <- FELLA::getCom(fellaData,
                        level = 4,
                        format = "id"
  ) %>% names()
  ## enzymes
  idEc <- FELLA::getCom(fellaData,
                        level = 3,
                        format = "id"
  ) %>% names()

  groups <- unique(pathDatFella$contrast)

  for (i in seq_along(groups)) {
    ## filtered data
    pathDatFellaFiltered <- pathDatFella[pathDatFella$contrast %in% groups[i], ]
    ## define compunds
    cpd <- unique(pathDatFellaFiltered$keggID)
    ## perform enricment analysis
    analysis <- FELLA::enrich(
      compounds = cpd,
      data = fellaData,
      method = network.method,
      approx = "normality"
    )

    ## create fellaplot function

    ## fella plot
    # net <- FELLA::plot(
    #   analysis,
    #   method = "diffusion",
    #   data = fellaData,
    #   nlimit = 250,
    #   plotLegend = TRUE,
    #   vertex.label.cex = 1,
    #   vertex.label.degree = pi,
    #   rescale = TRUE
    # )

    ## generateResultsGraph

    g <- FELLA::generateResultsGraph(
      object = analysis,
      data = fellaData,
      method = network.method
    )
    ## define undirected
    unionGraphUndir <- igraph::as.undirected(g, mode = "collapse")
    ## create igraph obj
    clp <- igraph::cluster_edge_betweenness(unionGraphUndir)

    ## obtain matrix properties
    hubscore <- igraph::hub.score(g)$vector
    authscore <- igraph::authority.score(g)$vector
    eigenvalue <- igraph::eigen_centrality(g)$vector
    graph.strength <- igraph::graph.strength(g)
    centrality <- igraph::degree(g) # degree centality
    ## generate matrix table
    gDf <- as.data.frame(
      list(
        Hubscore = hubscore,
        Authscore = authscore,
        Eigen = eigenvalue,
        strength = graph.strength,
        centrality = centrality
      ),
      stringsAsFactors = FALSE
    )
    ## define rownames
    gDf$keggPath <- row.names(gDf)
    ## add p scores statistics
    pscores <- FELLA::getPscores(
      object = analysis,
      method = network.method
    )
    ## generateResultsTable
    table <- FELLA::generateResultsTable(
      object = analysis,
      data = fellaData,
      method = network.method
    )
    ## p.adjust holm
    table$holm <- p.adjust(table$p.score, method = "holm")
    ## p.adjust fdr
    table$FDR <- p.adjust(table$p.score, method = "fdr")
    ## merge tables
    colnames(table)[1] <- "keggPath"
    table <- merge(table, gDf, by = "keggPath", all = FALSE)
    ## pathway impact
    table.plot <- subset(table, Entry.type %in% c("pathway", "reaction", "module"))
    table.plot$KEGG.name <- gsub(" -.*", "", table.plot$KEGG.name)

    ## lattice of annotated networks
    clust <- data.frame(cl = clp$membership)
    rownames(clust) <- names(igraph::V(unionGraphUndir))
    clust$desc <- table.plot$KEGG.name[match(rownames(clust), table.plot$keggPath)]

    ## coalesce cluster names
    clust <- clust %>%
      drop_na() %>%
      group_by(cl) %>%
      summarise(desc = paste(desc, collapse = ":")) %>%
      ungroup()

    n <- legend.pathway
    pat <- paste0("^([^:]+(?::[^:]+){", n - 1, "}).*")
    clust$desc <- sub(pat, "\\1", clust$desc)
    clust$desc <- gsub(":", "\n", clust$desc)

    colors <- colorRampPalette(RColorBrewer::brewer.pal(9, "Set1"))(length(clust$cl))
    colors <- paste0(colors, "50")
    Group <- gl(
      n = length(clust$cl), 1,
      labels = clust$desc[clust$cl]
    )
    mark.col <- colors[Group]

    if (save == "svg") {
      svg(
        paste(ref.path, "/enrichmentNetwork_", paste0("enrichmentNetwork_", groups[i], ".", save), sep = ""),
        width = fig.width,
        height = fig.height
      )
    } else if (save == "png") {
      png(
        paste(ref.path, "/enrichmentNetwork_", paste0("enrichmentNetwork_", groups[i], ".", save), sep = ""),
        width = fig.width,
        height = fig.height
      )
    } else if (save == "pdf") {
      pdf(
        paste(ref.path, "/enrichmentNetwork_", paste0("enrichmentNetwork_", groups[i], ".", save), sep = ""),
        width = fig.width,
        height = fig.height
      )
    }

    ## plot grid
    #par(mfrow = c(1, 2))

    ## plot
    plot(clp,
         unionGraphUndir,
         alpha = 0.5,
         mark.border = "black",
         vertex.size = (igraph::V(unionGraphUndir)$input + 0.75) * 5,
         vertex.label = NA,
         mark.col = mark.col,
         main = groups[i]
    )
    legend(bty = "n",
           cex = 0.7,
           legend = levels(Group),
           fill = colors,
           x="bottom",
           ncol = 2

    )

    if (save != "none") {
      ## print
      dev.off()
    }

    ## plot pathway impact
    ## plot
    p <- ggplot(
      table.plot,
      aes(
        x = centrality,
        y = -log10(p.score)
      )
    ) +
      geom_point(
        aes(
          size = centrality,
          fill = -log10(p.score)
        ),
        color = "black",
        pch = 21
      ) +
      ggtitle(paste0("Pathway impact:", groups[i])) +
      theme(legend.text.align = 0) +
      theme_bw() +
      theme(
        panel.border = element_rect(
          colour = "black",
          fill = NA,
          size = 1
        ),
        axis.text = element_text(
          size = 11,
          # face = "bold",
          colour = "black"
        ),
        axis.title = element_text(size = 12, face = "bold")
      ) +
      scale_fill_gradientn(
        colours = rev(RColorBrewer::brewer.pal(10, "RdYlBu")),
        limits = c(0, 8),
        oob = scales::squish,
        name = "fold changes"
      ) +
      guides(fill = guide_colourbar(
        barwidth = unit(0.3, "cm"),
        ticks.colour = "black",
        frame.colour = "black"
      )) +
      labs(
        x = "Pathway Impact",
        y = "p value (-log10)",
        fill = "p value",
        size = "Pathway size"
      ) +
      ggrepel::geom_text_repel(
        data = subset(
          table.plot,
          centrality >= quantile(centrality, 0.75)[[1]]
        ),
        aes(label = KEGG.name)
      )

    ## print plot
    plot.pathway.impact[[groups[i]]] <- p

    ## save enrichTable
    enrichment.results <- bind_rows(enrichment.results, table.plot)
  }

  return(list(
    results = enrichment.results,
    plot.pathway.impact = plot.pathway.impact
  ))
}
