ProcessCountDataFrameForPlotCounts <- function(gene.name.normalized.counts, 
                                               design.matrix, gene.name,
                                               symbols=NULL) 
{
    if(length(gene.name) > 1)
    {
        if(is.null(symbols)) stop("give some symbols!")
        
        gene.name.norm.counts.t <- data.frame()
        design.matrix$groupcol <- paste(design.matrix$genotype, design.matrix$condition, sep=":")
        i <- 1
        for(gene in gene.name)
        {
            
            gene.name.counts <- gene.name.normalized.counts[which(rownames(gene.name.normalized.counts) %in% gene), , drop=FALSE]
            gene.means <- lapply(unique(design.matrix$groupcol), function(x) 
            {
                idx <- which(design.matrix$groupcol %in% x)
                cols <- which(colnames(gene.name.counts) %in% rownames(design.matrix)[idx])
                m <- mean(gene.name.counts[cols])
                m
                
            })
            gene.means <- unlist(gene.means)
            rows <- t(as.data.frame((strsplit(unique(design.matrix$groupcol), ":"))))
            gene.df <- cbind(rows, gene.means)
            colnames(gene.df) <- c("genotype", "condition", "means")
            rownames(gene.df) <- NULL
            gene.df <- as.data.frame(gene.df)
            gene.df$genename <- symbols[i]
            gene.df$gcondition <- unique(design.matrix$groupcol)
            gene.name.norm.counts.t <- rbind(gene.name.norm.counts.t, gene.df)
            i <- i+1
        }
        gene.name.norm.counts.t <- gene.name.norm.counts.t[order(gene.name.norm.counts.t$means),]
        gene.name.norm.counts.t$means <- as.numeric(levels(gene.name.norm.counts.t$means))
        gene.name.norm.counts.t$gname <- paste0(gene.name.norm.counts.t$genotype, gene.name.norm.counts.t$genename)
        gene.name.norm.counts.t <- gene.name.norm.counts.t[order(gene.name.norm.counts.t$genotype),]
    } else {
        gene.name.normalized.counts <- gene.name.normalized.counts[which(rownames(gene.name.normalized.counts) %in% gene.name), , drop=FALSE]
        gene.name.norm.counts.t <- as.data.frame(t(gene.name.normalized.counts))
        gene.name.norm.counts.t$genename <- as.factor(gene.name)
        gene.name.norm.counts.t$condition <- as.character(design.matrix[which(rownames(design.matrix) %in% rownames(gene.name.norm.counts.t)), "condition"])
        gene.name.norm.counts.t$genotype <- as.character(design.matrix[which(rownames(design.matrix) %in% rownames(gene.name.norm.counts.t)), "genotype"])
        gene.name.norm.counts.t$log2counts <- log2(gene.name.norm.counts.t[,1])
        gene.name.norm.counts.t$counts <- gene.name.norm.counts.t[,1]
        gene.name.norm.counts.t$genename <- rep(symbols, times=dim(gene.name.norm.counts.t)[1])
    }
    return(gene.name.norm.counts.t)
}

geneProfileLucia <- function(normalized.counts, design.matrix, 
                             gene.name, res.o=NULL, show.plot=FALSE, 
                             plotly.flag=FALSE) 
{
    idx <- which(res.o$gene==gene.name)
    if(length(idx) > 0 )
    {
        gene.name.r <- rownames(res.o)[idx]
    } else {
        ## take the gene directly from the counts rownames 
        ## res.o not useful in this case
        idx <- which(rownames(res.o)==gene.name)
        if(length(idx) > 0 )
        {
            gene.name.r <- gene.name
        } else {
            warning("gene ", gene.name," not present!")
            return()
        }
        
    }
    gn.counts <- ProcessCountDataFrameForPlotCounts(
        gene.name.normalized.counts=normalized.counts,
        design.matrix=design.matrix, gene.name=gene.name.r)
    
    pp <- ggplot(gn.counts, 
                 aes_string(x="condition", y="counts", color="genotype")) + 
        geom_point() + 
        stat_smooth(data=gn.counts, 
                    mapping=aes(x=as.numeric(as.factor(condition)), 
                                y=counts, 
                                color=genotype), 
                    method = "lm", se=FALSE, fullrange=FALSE) +
        facet_grid(.~genotype) +
        ggtitle(paste( "Profile of", gene.name, "gene", sep=" "))
    
    if(show.plot) 
    {
        if(plotly.flag)
        {
            ggplotly(pp)
        } else {
            pp
        }
    } else {
        return(pp)
    }
}


geneGroupProfile <- function(normalized.counts, design.matrix, 
                            gene.names, res.o=NULL, 
                            show.plot=FALSE, 
                            plotly.flag=FALSE, log.flag=FALSE) 
{
    idx <- which(res.o$gene %in% gene.names)
    if(length(idx) > 0 )
    {
        gene.name.r <- rownames(res.o)[idx]
        gene.names <- res.o$gene[idx]
    } else {
        ## take the gene directly from the counts rownames 
        ## res.o not useful in this case
        idx <- which(rownames(res.o) %in% gene.names)
        if(length(idx) > 0 )
        {
            gene.name.r <- gene.names
        } else {
            warning("genes ", gene.names," not present!")
            return()
        }
        
    }
    gn.means <- ProcessCountDataFrameForPlotCounts(
        gene.name.normalized.counts=normalized.counts,
        design.matrix=design.matrix, gene.name=gene.name.r, symbols=gene.names)
    
    if(log.flag)
    {
        pp <- ggplot(gn.means, aes(y=log(gn.means$means), x=gn.means$condition, color=genename)) +
            geom_point() +
            geom_line(aes(y=log(gn.means$means), x=as.numeric(gn.means$condition), 
                          color=genename)) + 
            facet_grid(.~genotype) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("condition") +
            ylab("log(means)")
    } else {
        pp <- ggplot(gn.means, aes(y=gn.means$means, x=gn.means$condition, color=genename)) +
            geom_point() +
            geom_line(aes(y=gn.means$means, x=as.numeric(gn.means$condition), 
                          color=genename)) + 
            facet_grid(.~genotype) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("condition") +
            ylab("means")
    }
    
    if(show.plot) 
    {
        if(plotly.flag)
        {
            ggplotly(pp)
        } else {
            pp
        }
    } else {
        return(pp)
    }
}


geneGroupProfileRev <- function(normalized.counts, design.matrix, 
                             gene.names, res.o=NULL, 
                             show.plot=FALSE, 
                             plotly.flag=FALSE, log.flag=FALSE) 
{
    idx <- which(res.o$gene %in% gene.names)
    if(length(idx) > 0 )
    {
        gene.name.r <- rownames(res.o)[idx]
        gene.names <- res.o$gene[idx]
    } else {
        ## take the gene directly from the counts rownames 
        ## res.o not useful in this case
        idx <- which(rownames(res.o) %in% gene.names)
        if(length(idx) > 0 )
        {
            gene.name.r <- gene.names
        } else {
            warning("genes ", gene.names," not present!")
            return()
        }
        
    }
    gn.means <- ProcessCountDataFrameForPlotCounts(
        gene.name.normalized.counts=normalized.counts,
        design.matrix=design.matrix, gene.name=gene.name.r, symbols=gene.names)
    gn.means <- gn.means[order(gn.means$condition),]
    
    if(log.flag)
    {
        pp <- ggplot(gn.means, aes(y=log(gn.means$means), x=gn.means$genotype, color=genename)) +
            geom_point() +
            geom_line(aes(y=log(gn.means$means), x=as.numeric(gn.means$genotype), 
                          color=genename)) + 
            facet_grid(.~condition) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("genotype") +
            ylab("log(means)")
    } else {
        pp <- ggplot(gn.means, aes(y=gn.means$means, x=gn.means$genotype, color=genename)) +
            geom_point() +
            geom_line(aes(y=gn.means$means, x=as.numeric(gn.means$genotype), 
                          color=genename)) + 
            facet_grid(.~condition) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("genotype") +
            ylab("means")
    }
    
    if(show.plot) 
    {
        if(plotly.flag)
        {
            ggplotly(pp)
        } else {
            pp
        }
    } else {
        return(pp)
    }
}


geneGroupProfileRows <- function(normalized.counts, design.matrix, 
                             gene.names, res.o=NULL, show.plot=FALSE, 
                             plotly.flag=FALSE, log.flag=FALSE,
                             scale_facets="free_y") 
{
    idx <- which(res.o$gene %in% gene.names)
    if(length(idx) > 0 )
    {
        gene.name.r <- rownames(res.o)[idx]
        gene.names <- res.o[idx,]
    } else {
        ## take the gene directly from the counts rownames 
        ## res.o not useful in this case
        idx <- which(rownames(res.o) %in% gene.names)
        if(length(idx) > 0 )
        {
            gene.name.r <- gene.names
        } else {
            warning("genes ", gene.names," not present!")
            return()
        }
        
    }
    
    
    i=1
    for(gene in gene.names$check)
    {
        gn.count <- ProcessCountDataFrameForPlotCounts(
            gene.name.normalized.counts=normalized.counts,
            design.matrix=design.matrix, gene.name=gene, symbols=gene.names$gene[i])
        rownames(gn.count) <- NULL
        
        if(i==1) {
            gn.countss <- gn.count[,c(2:6)]
        } else {
            gn.countss <- rbind(gn.countss, gn.count[,c(2:6)])
        }
        i=i+1
    }
    # gn.means <- ProcessCountDataFrameForPlotCounts(
    #     gene.name.normalized.counts=normalized.counts,
    #     design.matrix=design.matrix, gene.name=gene.name.r, symbols=gene.names)
    
    gn.countss <- gn.countss[order(gn.countss$genename),]
    
        
    if(log.flag)
    {
        pp <- ggplot(gn.countss, aes(y=gn.countss$log2counts, x=gn.countss$condition, color=genename)) +
            geom_point() +
            stat_smooth(data=gn.countss, 
                mapping=aes(
                    x=as.numeric(as.factor(condition)),
                    y=gn.countss$log2counts,
                    color=genename),
                method="lm",
                se=FALSE, fullrange=FALSE) +
            facet_grid(genename~genotype, scales=scale_facets) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("condition") +
            ylab("log(counts)")
    } else {
        pp <- ggplot(gn.countss, aes(y=gn.countss$counts, x=gn.countss$condition, color=genename)) +
            geom_point() +
            stat_smooth(data=gn.countss, 
                        mapping=aes(
                            x=as.numeric(as.factor(condition)),
                            y=gn.countss$counts,
                            color=genename),
                        method="lm",
                        se=FALSE, fullrange=FALSE) +
            facet_grid(genename~genotype, scales=scale_facets) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("condition") +
            ylab("counts")
    }
    
    if(show.plot) 
    {
        if(plotly.flag)
        {
            ggplotly(pp)
        } else {
            pp
        }
    } else {
        return(pp)
    }
}



geneGroupProfileRowsRev <- function(normalized.counts, design.matrix, 
                                 gene.names, res.o=NULL, show.plot=FALSE, 
                                 plotly.flag=FALSE, log.flag=FALSE,
                                 scale_facets="free_y") 
{
    idx <- which(res.o$gene %in% gene.names)
    if(length(idx) > 0 )
    {
        gene.name.r <- rownames(res.o)[idx]
        gene.names <- res.o[idx,]
    } else {
        ## take the gene directly from the counts rownames 
        ## res.o not useful in this case
        idx <- which(rownames(res.o) %in% gene.names)
        if(length(idx) > 0 )
        {
            gene.name.r <- gene.names
        } else {
            warning("genes ", gene.names," not present!")
            return()
        }
        
    }
    
    
    i=1
    for(gene in gene.names$check)
    {
        gn.count <- ProcessCountDataFrameForPlotCounts(
            gene.name.normalized.counts=normalized.counts,
            design.matrix=design.matrix, gene.name=gene, symbols=gene.names$gene[i])
        rownames(gn.count) <- NULL
        
        if(i==1) {
            gn.countss <- gn.count[,c(2:6)]
        } else {
            gn.countss <- rbind(gn.countss, gn.count[,c(2:6)])
        }
        i=i+1
    }
    # gn.means <- ProcessCountDataFrameForPlotCounts(
    #     gene.name.normalized.counts=normalized.counts,
    #     design.matrix=design.matrix, gene.name=gene.name.r, symbols=gene.names)
    
    gn.countss <- gn.countss[order(gn.countss$condition),]
    gn.countss <- gn.countss[order(gn.countss$genename),]
    
    
    
    if(log.flag)
    {
        pp <- ggplot(gn.countss, aes(y=gn.countss$log2counts, x=gn.countss$genotype, color=genename)) +
            geom_point() +
            stat_smooth(data=gn.countss, 
                        mapping=aes(
                            x=as.numeric(as.factor(genotype)),
                            y=gn.countss$log2counts,
                            color=genename),
                        method="lm",
                        se=FALSE, fullrange=FALSE) +
            facet_grid(genename~condition, scales=scale_facets) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("genotype") +
            ylab("log(counts)")
    } else {
        pp <- ggplot(gn.countss, aes(y=gn.countss$counts, x=gn.countss$genotype, color=genename)) +
            geom_point() +
            stat_smooth(data=gn.countss, 
                        mapping=aes(
                            x=as.numeric(as.factor(genotype)),
                            y=gn.countss$counts,
                            color=genename),
                        method="lm",
                        se=FALSE, fullrange=FALSE) +
            facet_grid(genename~condition, scales=scale_facets) +
            ggtitle(paste( "Gene profiles", sep=" ")) +
            xlab("genotype") +
            ylab("counts")
    }
    
    if(show.plot) 
    {
        if(plotly.flag)
        {
            ggplotly(pp)
        } else {
            pp
        }
    } else {
        return(pp)
    }
}

