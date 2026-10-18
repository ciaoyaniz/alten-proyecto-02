\set ON_ERROR_STOP on

SELECT 'CREATE ROLE zbx_monitor LOGIN INHERIT'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'zbx_monitor')
\gexec

GRANT pg_monitor TO zbx_monitor;
GRANT CONNECT ON DATABASE postgres, labdb TO zbx_monitor;

\du zbx_monitor

-- Opciones configuradas:
-- ----------------------
-- \set ON_ERROR_STOP on -> psql se para en el primer error
-- SELECT ... WHERE NOT EXISTS + \gexec -> crea el rol solo si falta; se puede lanzar dos veces
-- LOGIN -> puede iniciar sesión; la contraseña no va en el archivo
-- INHERIT -> recibe los permisos de los roles que le doy
-- GRANT pg_monitor -> lee estadísticas y ajustes, no los datos de las tablas
-- GRANT CONNECT ON DATABASE postgres, labdb -> la plantilla entra en postgres y descubre labdb
-- \du zbx_monitor -> enseña el usuario como miembro de pg_monitor