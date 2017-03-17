library(RSQLite)
sqlitePath = "~/sql.db"
table = "responses"



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("CREATE TABLE %s(start REAL, end REAL, file TEXT, object TEXT, unique (start, end, file, object))", table)
    dbGetQuery(db, query)
    dbDisconnect(db)
}

saveData = function(start, end, file, object) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("INSERT INTO %s ('start', 'end', 'file', 'object') VALUES (:start, :end, :file, :object)", table)
    dbGetQuery(db, query, list(start=start, end=end, file=file, object=object))
    dbDisconnect(db)
}


loadData = function() {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("SELECT * FROM %s", table)
    data = dbGetQuery(db, query)
    dbDisconnect(db)
    data
}

deleteData = function(start, end, file, object) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("DELETE FROM %s WHERE start=:start and end=:end and file=:file and object=:object", table)
    dbGetQuery(db, query, list(start=start, end=end, file=file, object=object))
    dbDisconnect(db)
    data
}
