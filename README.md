# PrestaControl para Android

App Flutter con Material 3. Permite crear una cuenta, iniciar sesión, guardar la sesión de manera segura, gestionar préstamos y consultar el resumen de cartera. Incluye los filtros **Por cobrar** y **Cobrados**, vencidos en rojo y búsqueda por nombre o DNI dentro del filtro activo.

## Android Studio

1. Instala o habilita el plugin **Flutter**. Abre la carpeta completa `prestacontrol_app` con **File → Open**.
2. Configura el SDK de Flutter y ejecuta `flutter pub get` desde la terminal de Android Studio.
3. Con la API local en el puerto 8080, selecciona un emulador Android y pulsa **Run**. La URL predeterminada en modo debug para el emulador es `http://10.0.2.2:8080`.

### Celular por USB

En el celular, habilita la depuración USB y autoriza a tu computadora. Conecta el celular, inicia la API local y ejecuta desde la carpeta de la app:

```powershell
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Con varios dispositivos conectados, elige el serial con `adb -s SERIAL reverse tcp:8080 tcp:8080` y `flutter run -d SERIAL`. Para un APK local usa `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080`. El reenvío USB permite a ese APK acceder a la API en la PC.

### APK para Render

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://TU-API.onrender.com
```

El APK queda en `build/app/outputs/flutter-apk/`. El modo release requiere la URL HTTPS configurada con `API_BASE_URL`.

## Flujo de exposición

Registra una cuenta de prueba. Crea un préstamo con un DNI ficticio, por ejemplo `01234567`, un capital de S/ 500 y un interés de 12 %. Comprueba el total de S/ 560, búscalo por DNI, edítalo y márcalo como pagado desde el menú. Verifica que aparece en **Cobrados** y sale del saldo pendiente. Cierra y reabre la app para comprobar que conserva la sesión. Para finalizar, usa el botón de cerrar sesión y comprueba que vuelve a la pantalla de acceso.
