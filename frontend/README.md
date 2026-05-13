# WearIt — Frontend Flutter

App móvil para el proyecto WearIt, conectada al backend Spring Boot.

## Estructura del proyecto

```
lib/
├── main.dart                    # Entrada + Splash screen
├── theme/
│   └── app_theme.dart           # Colores, fuentes, estilos globales
├── services/
│   └── api_service.dart         # Cliente HTTP — todas las llamadas a la API
├── screens/
│   ├── auth_screen.dart         # Login y Registro
│   ├── main_screen.dart         # Navegación principal (bottom nav)
│   ├── feed_screen.dart         # Feed público + widget tiempo
│   ├── prendas_screen.dart      # Armario personal
│   ├── prenda_form_screen.dart  # Crear/editar prenda
│   ├── outfits_screen.dart      # Mis outfits + ranking
│   ├── outfit_form_screen.dart  # Crear/editar outfit
│   ├── sugerencias_screen.dart  # Sugerencias de outfits
│   └── perfil_screen.dart       # Perfil + historial
└── widgets/
    └── outfit_card.dart         # Card reutilizable con like
```

## Configuración

En `lib/services/api_service.dart`, cambia `baseUrl` según tu entorno:

```dart
// Emulador Android
static const String baseUrl = 'http://10.0.2.2:8080/api';

// Dispositivo físico (pon la IP de tu ordenador)
static const String baseUrl = 'http://192.168.x.x:8080/api';

// Emulador iOS
static const String baseUrl = 'http://localhost:8080/api';
```

## Instalación y ejecución

### Requisitos
- Flutter SDK 3.x
- Android Studio / VS Code con extensión Flutter
- Backend WearIt corriendo en el puerto 8080

### Pasos

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Lanzar en emulador o dispositivo
flutter run

# 3. (Opcional) Build APK debug
flutter build apk --debug
```

## Pantallas

| Pantalla | Descripción |
|----------|-------------|
| Splash | Animación de entrada + comprobación de sesión |
| Login/Registro | Autenticación con JWT |
| Feed | Outfits públicos + clima en tiempo real |
| Armario | Gestión de prendas (CRUD + filtros) |
| Outfits | Mis outfits + ranking por likes |
| Ideas | Sugerencias de outfits por estilo y tiempo |
| Perfil | Datos del usuario + historial de looks |