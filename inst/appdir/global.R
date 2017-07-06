library(RSQLite)
sqlitePath = sqlitePath
table = 'responses'
table2 = 'landmarks'



# if file empty, create it
if(!file.exists(sqlitePath)) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("CREATE TABLE %s(start REAL, file TEXT, object TEXT, inverted INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, unique (start, file, object))", table)
    dbGetQuery(db, query)
    query2 = sprintf("CREATE TABLE %s(landmark TEXT, value REAL, description TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, unique(landmark, description))", table2)
    dbGetQuery(db, query2)
    dbDisconnect(db)
}

saveData = function(start, file, object, inverted) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("INSERT INTO %s ('start', 'file', 'object', 'inverted') VALUES (:start, :file, :object, :inverted)", table)
    dbSendQuery(db, query, list(start = start, file = file, object = object, inverted = inverted))
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


saveLandmark = function(landmark, value, description) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("INSERT INTO %s ('landmark', 'value', 'description') VALUES (:landmark, :value, :description)", table2)
    dbGetQuery(db, query, list(landmark = landmark, value = value, description = description))
    dbDisconnect(db)
}


loadLandmarks = function() {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("SELECT landmark, value, description FROM %s", table2)
    data = dbGetQuery(db, query)
    dbDisconnect(db)
    data
}


deleteLandmark = function(landmark, description) {
    db = dbConnect(SQLite(), sqlitePath)
    query = sprintf("DELETE FROM %s WHERE landmark=:landmark and description=:description", table2)
    dbGetQuery(db, query, list(landmark = landmark, description = description))
    dbDisconnect(db)
    data
}

