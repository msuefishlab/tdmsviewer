library(RSQLite)
sqlitePath <- "~/sql.db"
table <- "responses"



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db <- dbConnect(SQLite(), sqlitePath)
    query <- "CREATE TABLE responses(start REAL, end REAL, file VARCHAR(255), unique (start, end, file))"
    dbGetQuery(db, query)
    dbDisconnect(db)
}

saveData <- function(data) {
    db <- dbConnect(SQLite(), sqlitePath)
    query <- sprintf(
        "INSERT INTO %s (%s) VALUES ('%s')",
        table, 
        paste(names(data), collapse = ", "),
        paste(data, collapse = "', '")
    )
    dbGetQuery(db, query)
    dbDisconnect(db)
}


loadData <- function() {
    db <- dbConnect(SQLite(), sqlitePath)
    query <- sprintf("SELECT * FROM %s", table)
    data <- dbGetQuery(db, query)
    dbDisconnect(db)
    data
}
