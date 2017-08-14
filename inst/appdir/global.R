library(RSQLite)
sqlitePath = sqlitePath
table = 'responses'
table2 = 'landmarks'



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db = dbConnect(SQLite(), sqlitePath)
    on.exit(dbDisconnect(db)) 
    query = sprintf("CREATE TABLE %s(start REAL, file TEXT, object TEXT, inverted INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, unique (start, file, object))", table)
    dbSendQuery(db, query)
    query2 = sprintf("CREATE TABLE %s(landmark TEXT, value REAL, description TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, unique(landmark, description))", table2)
    dbSendQuery(db, query2)
}



saveLandmark = function(landmark, value, description) {
    db = dbConnect(SQLite(), sqlitePath)
    on.exit(dbDisconnect(db)) 
    query = sprintf("INSERT INTO %s ('landmark', 'value', 'description') VALUES (:landmark, :value, :description)", table2)
    dbSendQuery(db, query, list(landmark = landmark, value = value, description = description))
}


loadLandmarks = function() {
    db = dbConnect(SQLite(), sqlitePath)
    on.exit(dbDisconnect(db)) 
    query = sprintf("SELECT landmark, value, description FROM %s", table2)
    dbGetQuery(db, query)
}


deleteLandmark = function(landmark, description) {
    db = dbConnect(SQLite(), sqlitePath)
    on.exit(dbDisconnect(db)) 
    query = sprintf("DELETE FROM %s WHERE landmark=:landmark and description=:description", table2)
    dbSendQuery(db, query, list(landmark = landmark, description = description))
}

