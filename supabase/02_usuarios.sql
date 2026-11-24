-- =====================================================================
-- WRCtech Tickets - Asignar rol a cada usuario
-- Correr DESPUÉS de crear los 3 usuarios en Authentication > Users.
-- Cambiá los emails por los que usaste.
-- =====================================================================

insert into perfiles (id, nombre, rol)
select id, 'Celular farmacia', 'farmacia'
from auth.users where email = 'wrctech.sistemas+farmacia@gmail.com';

insert into perfiles (id, nombre, rol)
select id, 'Sistemas', 'tecnico'
from auth.users where email = 'wrctech.sistemas+tecnico@gmail.com';

insert into perfiles (id, nombre, rol)
select id, 'Farmacéutico', 'farmaceutico'
from auth.users where email = 'wrctech.sistemas+farmaceutico@gmail.com';

-- Verificación: tienen que aparecer 3 filas
select p.nombre, p.rol, u.email
from perfiles p join auth.users u on u.id = p.id;
