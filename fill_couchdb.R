library(sofa)
library(data.table)
library(exforParser)

exforFiles <- list.files(".",
                         pattern="entry.*txt", full.names=TRUE)

m <- Cushion$new(
    host = "localhost",
    transport = 'http',
    port = 5984,
    user = 'admin',
    pwd = 'password'
)

db_create(m, dbname ='exfor')

errorCounter <- 0
errorFiles <- character(0)

# loop over entries
jsonStrs <- character(0)

for (idx in seq_along(exforFiles)) {

    cat("read file ", idx, " of ", length(exforFiles), "\n")
    curFile <- exforFiles[idx]
    curText <- try(readChar(curFile, file.info(curFile)$size), silent=TRUE) 
    if ("try-error" %in% class(curText)) 
    {
        cat("Problems reading ", curFile, "\n")
        errorCounter <- errorCounter + 1
        errorFiles <- c(errorFiles, curFile)
        next
    }
    curEntry <- parseEntry(curText)
    firstSub <- NULL
    # loop over subentries
    for (idx2 in seq_along(curEntry$SUBENT)) {
        curSub <- curEntry$SUBENT[[idx2]]
        if (idx2==1) 
        {
            firstSub <- curSub
        }
        else
        {
            curSub <- transformSubent(firstSub,curSub)
        }
        curSub[["_id"]] <- curSub[["ID"]]
        jsonObj <- convToJSON(curSub)
        jsonStrs <- c(jsonStrs, jsonObj)
        if (length(jsonStrs) >= 200)
        {
            db_bulk_create(m, "exfor", jsonStrs, as='json')
            jsonStrs <- character(0)
        }
    }
}

if (length(jsonStrs) > 0) {
    db_bulk_create(m, "exfor", jsonStrs)
    jsonStrs <- character(0)
}

