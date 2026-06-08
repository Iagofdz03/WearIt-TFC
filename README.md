# WearIt - Smart Wardrobe

WearIt es una aplicación móvil de armario digital inteligente que permite gestionar prendas, crear outfits de forma visual y recibir sugerencias basadas en el clima y tendencias sociales.

Desarrollado con Flutter + Spring Boot, incluye autenticación JWT, canvas interactivo y sistema social de outfits.

---

# Tecnologías

- **Frontend:** Flutter (Dart)
- **Backend:** Spring Boot 3 (Java 17)
- **Base de datos:** MySQL
- **APIs externas:**
  - OpenWeatherMap (clima)
  - remove.bg (eliminación de fondos)

---

# Estructura del proyecto

WearIt-TFC/
├── Backend/
│   ├── src/main/java/com/wearit/
│   │   ├── config/
│   │   ├── controller/
│   │   ├── service/
│   │   ├── repository/
│   │   ├── model/
│   │   ├── dto/
│   │   └── WearitApplication.java
│   ├── src/main/resources/
│   │   └── application.properties
│   └── pom.xml
│
├── frontend/
│   ├── lib/
│   │   ├── api/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   ├── feed/
│   │   │   ├── main/
│   │   │   ├── outfits/
│   │   │   ├── perfil/
│   │   │   ├── prendas/
│   │   │   ├── social/
│   │   │   └── sugerencias/
│   │   ├── widgets/
│   │   ├── theme/
│   │   └── main.dart
│
├── docs/data/wearit_seed.sql
├── uploads/
└── README.md

---

# Instalación rápida

Clona el repositorio y entra en la carpeta principal:

git clone https://github.com/Iagofdz03/WearIt-TFC.git  
cd WearIt-TFC  

Dale permisos a los scripts (Linux/Mac):

chmod +x scripts/*.sh  

Inicializa la base de datos:

mysql -u root -p < docs/data/wearit_seed.sql  

Instala backend y frontend:

cd Backend  
./mvnw clean install  

cd ../frontend  
flutter pub get  

---

# Ejecución del proyecto

Backend:

cd Backend  
./mvnw spring-boot:run  

Frontend:

cd frontend  
flutter run  

Generar APK:

cd frontend  
flutter build apk  

---

# Configuración de base de datos

spring.datasource.url=jdbc:mysql://localhost:3306/wearit_db  
spring.datasource.username=root  
spring.datasource.password=tu_contraseña  

jwt.secret=clave_secreta  

---

# Pruebas rápidas

Registro:

curl -X POST http://localhost:8080/api/usuarios \
-H "Content-Type: application/json" \
-d '{"nombre":"Test","email":"test@test.com","password":"123456"}'

Login:

curl -X POST http://localhost:8080/api/auth/login \
-H "Content-Type: application/json" \
-d '{"email":"test@test.com","password":"123456"}'

Feed:

curl -X GET http://localhost:8080/api/outfits/publicos

Clima:

curl -X GET http://localhost:8080/api/tiempo/Madrid  

---

# Problemas comunes

JWT error → revisar jwt.secret  
MySQL error → iniciar servicio MySQL  
CORS error → revisar configuración del backend  

---

# Licencia

MIT
