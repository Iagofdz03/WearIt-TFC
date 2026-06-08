-- ============================================================
-- WearIt — Script de datos de ejemplo (wearit_seed.sql)
-- Las tablas las crea Hibernate automáticamente al arrancar.
-- Ejecutar este script DESPUÉS del primer arranque del backend.
-- Contraseñas: BCrypt de "test1234"(ejemplo, ejecutar la siguiente linea para obtener)
System.out.println(new BCryptPasswordEncoder().encode("test1234"));
-- ============================================================

-- ── USUARIOS ─────────────────────────────────────────────────
INSERT INTO usuario (nombre, email, password, tema, fecha_registro) VALUES
('Ana García',    'usuario1@wearit.es', '$2a$10$7QxZ1kL9mN3pR5sT8vW2uOeKjHdFgYbXcAiMnPqLrStUvWxYzAbCd', 'neutro',    NOW()),
('Carlos López',  'usuario2@wearit.es', '$2a$10$7QxZ1kL9mN3pR5sT8vW2uOeKjHdFgYbXcAiMnPqLrStUvWxYzAbCd', 'masculino', NOW());

-- ── PRENDAS usuario 1 ─────────────────────────────────────────
INSERT INTO prenda (nombre, tipo, color, estilo, temporada, foto_url, fecha_anadida, usuario_id) VALUES
('Camiseta blanca básica',   'camiseta',  'blanco', 'casual',    'todo año',  NULL, NOW(), 1),
('Camiseta negra oversize',  'camiseta',  'negro',  'casual',    'todo año',  NULL, NOW(), 1),
('Pantalón vaquero azul',    'pantalón',  'azul',   'casual',    'todo año',  NULL, NOW(), 1),
('Pantalón negro slim',      'pantalón',  'negro',  'formal',    'todo año',  NULL, NOW(), 1),
('Chaqueta beige',           'chaqueta',  'beige',  'casual',    'otoño',     NULL, NOW(), 1),
('Vestido rojo elegante',    'vestido',   'rojo',   'elegante',  'verano',    NULL, NOW(), 1),
('Zapatillas blancas',       'zapatos',   'blanco', 'casual',    'todo año',  NULL, NOW(), 1),
('Zapatos negros de tacón',  'zapatos',   'negro',  'formal',    'todo año',  NULL, NOW(), 1),
('Bolso marrón',             'bolso',     'marrón', 'casual',    'todo año',  NULL, NOW(), 1),
('Jersey gris punto',        'jersey',    'gris',   'casual',    'invierno',  NULL, NOW(), 1);

-- ── PRENDAS usuario 2 ─────────────────────────────────────────
INSERT INTO prenda (nombre, tipo, color, estilo, temporada, foto_url, fecha_anadida, usuario_id) VALUES
('Camiseta azul marino',     'camiseta',  'azul',   'casual',    'todo año',  NULL, NOW(), 2),
('Pantalón gris chino',      'pantalón',  'gris',   'formal',    'todo año',  NULL, NOW(), 2),
('Chaqueta negra cuero',     'chaqueta',  'negro',  'urbano',    'otoño',     NULL, NOW(), 2),
('Zapatillas negras',        'zapatos',   'negro',  'casual',    'todo año',  NULL, NOW(), 2),
('Camiseta blanca polo',     'camiseta',  'blanco', 'formal',    'verano',    NULL, NOW(), 2);

-- ── OUTFITS ───────────────────────────────────────────────────
INSERT INTO outfit (nombre, ocasion, es_publico, foto_portada, fecha_creacion, usuario_id) VALUES
('Look casual diario',    'casual',  true,  NULL, NOW(), 1),
('Outfit de oficina',     'trabajo', true,  NULL, NOW(), 1),
('Look verano elegante',  'fiesta',  true,  NULL, NOW(), 1),
('Estilo urbano',         'casual',  true,  NULL, NOW(), 2),
('Look formal trabajo',   'trabajo', false, NULL, NOW(), 2);

-- ── OUTFIT_PRENDA (relación ManyToMany) ───────────────────────
-- Look casual diario (outfit 1): camiseta blanca + pantalón vaquero + zapatillas
INSERT INTO outfit_prenda (outfit_id, prenda_id) VALUES (1, 1), (1, 3), (1, 7);

-- Outfit de oficina (outfit 2): camiseta negra + pantalón negro + zapatos negros
INSERT INTO outfit_prenda (outfit_id, prenda_id) VALUES (2, 2), (2, 4), (2, 8);

-- Look verano elegante (outfit 3): vestido rojo + zapatos negros + bolso
INSERT INTO outfit_prenda (outfit_id, prenda_id) VALUES (3, 6), (3, 8), (3, 9);

-- Estilo urbano (outfit 4): camiseta azul + pantalón gris + chaqueta negra + zapatillas
INSERT INTO outfit_prenda (outfit_id, prenda_id) VALUES (4, 11), (4, 12), (4, 13), (4, 14);

-- Look formal trabajo (outfit 5): polo blanco + pantalón gris + zapatillas negras
INSERT INTO outfit_prenda (outfit_id, prenda_id) VALUES (5, 15), (5, 12), (5, 14);

-- ── LIKES ─────────────────────────────────────────────────────
INSERT INTO likes (usuario_id, outfit_id, fecha) VALUES
(2, 1, NOW()),
(2, 3, NOW()),
(1, 4, NOW());

-- ── HISTORIAL ─────────────────────────────────────────────────
INSERT INTO historial_outfit (usuario_id, outfit_id, fecha_uso) VALUES
(1, 1, NOW()),
(1, 2, NOW()),
(2, 4, NOW());

--El script crea dos usuarios de prueba (usuario1@wearit.es / usuario2@wearit.es con contraseña test1234), varias prendas de ejemplo y algunos outfits públicos para poder explorar el feed sin necesidad de registrarse desde cero.
