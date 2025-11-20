// Crear restricciones de unicidad (automáticamente crea índices)
CREATE CONSTRAINT FOR (u:User) REQUIRE u.user_id IS UNIQUE;
CREATE CONSTRAINT FOR (v:Visitor) REQUIRE v.id IS UNIQUE;
CREATE CONSTRAINT FOR (s:Session) REQUIRE s.session_id IS UNIQUE;
CREATE CONSTRAINT FOR (e:Event) REQUIRE e.event_id IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {user_id: row.user_id})
SET u.first_name = row.first_name,
    u.last_name = row.last_name,
    u.email = row.email,
    u.city = row.city,
    u.registration_date = datetime(row.registration_date);

LOAD CSV WITH HEADERS FROM 'file:///sessions.csv' AS row
MERGE (s:Session {session_id: row.session_id})
SET s.date = datetime(row.session_date),
    s.source = row.source,
    s.medium = row.medium,
    s.device = row.device

// 1. Crear el nodo Visitor (la cookie del navegador)
MERGE (v:Visitor {id: row.user_pseudo_id})

// 2. Relacionar Visitor con la Sesión (siempre ocurre)
MERGE (v)-[:INICIO_SESION]->(s)

// 3. Lógica Condicional para Usuarios Logueados
WITH row, s, v
CALL {
    WITH row, s, v
    // Solo procedemos si hay un user_id en la fila
    WITH row, s, v WHERE row.user_id IS NOT NULL AND row.user_id <> ""
    
    // Buscamos al usuario (ya cargado en el paso anterior)
    MATCH (u:User {user_id: row.user_id})
    
    // A. Relación solicitada: El usuario REALIZO la sesión
    MERGE (u)-[:REALIZO]->(s)
    
    // B. User Stitching: Identificamos que este Visitor ES este Usuario
    // Esto permitirá al grafo saber que el historial anónimo de 'v' pertenece a 'u'
    MERGE (v)-[:IDENTIFIED_AS]->(u)
} IN TRANSACTIONS;

LOAD CSV WITH HEADERS FROM 'file:///events.csv' AS row
MERGE (e:Event {event_id: row.event_id})
SET e.name = row.event_name,
    e.timestamp = datetime(row.event_timestamp),
    e.url = row.page_location,
    e.title = row.page_title

// Conectar el evento a la sesión
WITH row, e
MATCH (s:Session {session_id: row.session_id})
MERGE (s)-[:CONTIENE]->(e);