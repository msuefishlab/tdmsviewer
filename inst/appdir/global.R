library(RSQLite)
sqlitePath = '~/sql.db'
table = 'responses'
table2 = 'landmarks'



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("CREATE TABLE %s(start REAL, file TEXT, object TEXT, inverted INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, unique (start, file, object))", table)
    dbGetQuery(db, query)
    dbDisconnect(db)
}

saveData = function(start, file, object, inverted) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("INSERT INTO %s ('start', 'file', 'object', 'inverted') VALUES (:start, :file, :object, :inverted)", table)
    dbGetQuery(db, query, list(start = start, file = file, object = object, inverted = inverted))
    dbDisconnect(db)
}


loadData = function() {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("SELECT start, file, object, inverted, timestamp FROM %s", table)
    data = dbGetQuery(db, query)
    dbDisconnect(db)
    data
}

deleteData = function(start, file, object) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("DELETE FROM %s WHERE start=:start and file=:file and object=:object", table)
    dbGetQuery(db, query, list(start = start, file = file, object = object))
    dbDisconnect(db)
    data
}
