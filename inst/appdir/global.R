library(RSQLite)
sqlitePath = "~/sql.db"
table = "responses"



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("CREATE TABLE %s(start REAL, file TEXT, object TEXT, unique (start, file, object))", table)
    dbGetQuery(db, query)
    dbDisconnect(db)
}

saveData = function(start, file, object) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("INSERT INTO %s ('start', 'file', 'object') VALUES (:start, :file, :object)", table)
    dbGetQuery(db, query, list(start=start, file=file, object=object))
    dbDisconnect(db)
}


loadData = function() {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("SELECT start, file, object FROM %s", table)
    data = dbGetQuery(db, query)
    dbDisconnect(db)
    data
}

deleteData = function(start, file, object) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("DELETE FROM %s WHERE start=:start and file=:file and object=:object", table)
    dbGetQuery(db, query, list(start=start, file=file, object=object))
    dbDisconnect(db)
    data
}
