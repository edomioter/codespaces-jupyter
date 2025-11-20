// Esta query busca sesiones donde el usuario NO estaba logueado, pero que sabemos que son suyas gracias al enlace IDENTIFIED_AS
MATCH (u:User {email: 'un_email_del_csv@example.com'})
// Encontrar la "huella digital" (Visitor) asociada a este usuario
MATCH (v:Visitor)-[:IDENTIFIED_AS]->(u)
// Buscar TODAS las sesiones de esa huella (anónimas o no)
MATCH (v)-[:INICIO_SESION]->(s:Session)
// Opcional: Ver qué páginas vio
MATCH (s)-[:CONTIENE]->(e:Event)
RETURN u.email, s.session_id, s.date, e.title, 
       CASE WHEN (u)-[:REALIZO]->(s) THEN 'Logueado' ELSE 'Anónimo' END as estado
ORDER BY s.date ASC


// Cuando le preguntes al LLM: "¿Qué intereses mostró el usuario X antes de registrarse?", el grafo responderá recuperando
// nodos Event conectados al Visitor vinculados al User, pero cuya fecha de sesión sea anterior a u.registration_date.
MATCH (u:User)-[:IDENTIFIED_AS]-(v:Visitor)-[:INICIO_SESION]->(s:Session)-[:CONTIENE]->(e:Event)
WHERE s.date < u.registration_date
RETURN u.first_name, e.title, e.url