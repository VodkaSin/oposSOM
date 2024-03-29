library(biomaRt)
library(oposSOM)
library(stringr)
library(dplyr)

# OposSOM
runSom <- function(DT,outputname,dataset,dimension,filter='ensembl_gene_id'){
  # Parameters:
  #   DT: data.frame, input is recommended to be transformed into
  #       logarithmic scale
  #   outputname: char, name of the output file
  #   dimension: num(int), k value of SOM maps
  #   type: char, optional, default ensembl gene ID
  # Output: file containing OposSOM results in wd
  
  # Initialization
  env <- opossom.new(list(dataset.name=c(outputname),
                          dim.1stLvlSom=dimension,
                          database.dataset=dataset,
                          database.id.type=filter
  ))
  data <- data.matrix(DT)
  env$indata <- data
  
  # Modify whenever changing dataset
  env$group.labels <- c(rep("CGRP",2),
                        rep("CMV",2),
                        rep("CCSP",2),
                        "SPC")
  env$group.colors <- c(rep("gold",2),
                        rep("red",2),
                        rep("blue",2),
                        "green")
  opossom.run(env)
}


# BiomaRt Initialization, change version and dataset when needed
ensembl = useEnsembl(biomart='ensembl',version=105)

# Uncomment when unsure:
# View(listDatasets(ensembl))
# View(listAttributes(ensembl))
# View(listFilters(ensembl))

readGroup <- function(fileloc,grpcode){
  # grpcode: {'A','B','C', etc.}
  # Modify spot class if needed:
  # Group Overexpression Spots 
  # D-Cluster 
  # K-Means Cluster 
  # Overexpression Spots 
  group <- read.csv(paste0(fileloc,
                           '/CSV Sheets/Spot Lists/Group Overexpression Spots ',grpcode,'.csv'))
}

getIDs <- function(group,sourceIDs=NA){
  if (!is.na(sourceIDs)){
    items <- group[['ID']]
    ID <- sourceIDs[items]
    return(ID)
  }
  else{
    return(group[[1]])
  }
}

getResults <- function(fileloc,ID,filter,savefile=FALSE,grpcode='NA'){
  # Output attributes, configure identifier/filters denoted by filters,
  # Query items - values
  anno <- getBM(attributes=c('external_gene_name',
                                'ensembl_gene_id',
                                #'chromosome_name',
                                #'gene_biotype',
                                'description',
                                'name_1006'),
                   filters=filter,
                   values=ID,
                   mart=ensembl)
  if (savefile==TRUE) 
    {write.csv(anno,file=paste0(fileloc,'/GSEA Group ',grpcode,'.csv'))}
  return(anno)
}

bindResults <- function(group,results,fileloc,grpcode,ID,filter){
  group$Symbol = ID
  new <- left_join(group,results,by=c('Symbol'=filter))
  new <- subset(new, select = -c(X,Chromosome,Description))
  write.csv(new,file=paste0(fileloc,'/new GSEA Group ',grpcode,'.csv'))
  return(new)
}

getEnrichgrp <- function(fileloc,grpcode,sourceIDs,filter){
  group <- readGroup(fileloc,grpcode)
  ID <- getIDs(group,sourceIDs)
  results <- getResults(fileloc,ID,filter)
  enrich <- bindResults(group,results,fileloc,grpcode,ID,filter)
}

getEnrichall <- function(fileloc,filter,sourceIDs=NA){
  files <- paste0(fileloc,'/CSV Sheets/Spot Lists')
  ind <- length(list.files(files, pattern = 'Group '))
  grpcodes <- LETTERS[1:ind]
  print(grpcodes)
  for (grpcode in grpcodes){
    getEnrichgrp(fileloc,grpcode,sourceIDs,filter)
  }
}

# Sample Input #
# Working directory
#> wd <- getwd()
# Gene data
#> DT <- read.csv('GSE165766_TPM_filt.csv',row.names = 1)
#> filter <- 'ensembl_gene_id'
# Output file name & location
#> outname <- 'Small lung cancer (50)'
#> fileloc <- paste0(wd,'/',outname,' - Results')
# Run OposSOM
#> runsom(DT1,outname,dimension=50,filter)
# Initialize BiomaRt
#> ensembl = useDataset('mmusculus_gene_ensembl',mart=ensembl)
# Run enrichment analysis
#> getEnrichall(fileloc,filter)
