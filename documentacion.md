# 📚 Documentación del Proyecto Azar S.A.

Este documento explica la arquitectura del sistema, la responsabilidad de cada archivo y el propósito de cada una de sus funciones principales.

---

## 📁 Archivos Principales (Raíz de `lib/`)

### 1. `lib/estructura.ex` (`Estructura`)
Es el punto de entrada principal de la aplicación. Se encarga de mostrar los menús interactivos en consola y de conectar al jugador con las funcionalidades del sistema.
* **`main/0`**: Inicia los servicios de fondo (GenServers) y lanza el menú principal.
* **`iniciar_servicios/0`**: Verifica si el servidor de sorteos y el notificador están corriendo; si no, los enciende.
* **`menu_principal/0`**: Muestra las opciones de entrar como Administrador, Jugador o Salir.
* **`menu_jugador_login/0`**: Menú para que un jugador inicie sesión o se registre.
* **`registrar_jugador/0`**: Pide los datos al usuario, los valida y lo registra en el sistema.
* **`ingresar_tarjeta_valida/0`**: Pide la tarjeta en bucle hasta que sea válida (13 a 19 dígitos).
* **`login_jugador/0`**: Pide identificación y contraseña e inicia la sesión.
* **`menu_jugador/1`**: El panel de control del jugador autenticado (ver sorteos, comprar, historial, etc).
* **`ver_sorteos/1`, `comprar_billete/1`, `ver_historial/1`, etc**: Sub-flujos para cada acción específica del jugador.

### 2. `lib/util.ex` (`Azar.Util`)
Contiene herramientas "utilitarias" que son usadas por todos los demás archivos (para leer teclado, formatear textos, etc).
* **`mostrar_mensaje/1`**: Imprime un mensaje en pantalla.
* **`ingresar/2`**: Lee entradas del usuario por consola de forma segura y las convierte al tipo deseado (`:texto`, `:entero`, `:real`, `:boolean`).
* **`mostrar_error/1`**: Imprime un error en color rojo o salida de error.
* **`formatear_moneda/1`**: Convierte un número (ej. `1500.5`) a un string con formato de dinero (`$1500.50`).
* **`fecha_actual/0` / `fecha_hora_actual/0`**: Devuelven la hora del reloj del sistema.
* **`calcular_factorial/1` / `calcular_permutaciones_circulares/1`**: Funciones matemáticas auxiliares.

---

## 📁 Lógica de Negocio (`lib/azar/`)

### 3. `lib/azar/admin.ex` (`Azar.Admin`)
Maneja el menú y las acciones exclusivas del rol Administrador.
* **`menu/0`**: Muestra las opciones de crear sorteos, listar, cerrar y ver reportes.
* **Funciones `crear_sorteo`, `listar_sorteos`, `cerrar_sorteo`**: Piden los datos necesarios al administrador y envían la orden al `SorteoServer` para que los procese.

### 4. `lib/azar/jugador.ex` (`Azar.Jugador`)
Maneja la estructura de datos (struct) de un Jugador y cómo se guarda en el archivo JSON.
* **`defstruct`**: Define qué campos tiene un jugador (nombre, identificación, contrasena, saldo, premios).
* **`crear/4`**: Construye el objeto de un nuevo jugador en memoria.
* **`actualizar_saldo/2`**: Suma o resta dinero de la cuenta del jugador, validando que no quede en negativo.
* **`agregar_premio/2`**: Agrega un premio al historial del jugador.
* **`escribir_json/2` / `guardar_todos/1`**: Convierten la lista de jugadores a texto JSON y lo guardan en `jugadores.json`.
* **`cargar_jugadores/1`**: Lee el archivo JSON y lo convierte de vuelta a structs de Elixir.
* **`actualizar_en_json/1`**: Busca un jugador específico en el archivo y sobreescribe sus datos (útil al recargar saldo).

### 5. `lib/azar/autenticacion.ex` (`Azar.Autenticacion`)
Centraliza las reglas de seguridad para entrar al sistema.
* **`registrar/4`**: Aplica validaciones y, si todo está bien, le dice a `Jugador` que guarde la cuenta.
* **`iniciar_sesion/2`**: Busca el jugador en el JSON y verifica que la contraseña coincida.
* **`validar_tarjeta/1`**: Asegura que la tarjeta solo tenga números y tenga una longitud válida.
* **`validar_campos`, `validar_contraseña`, `validar_no_duplicado`**: Reglas internas de validación.

### 6. `lib/azar/sorteo_server.ex` (`Azar.SorteoServer`)
Es el corazón concurrente de la app. Un `GenServer` (un proceso de fondo) que mantiene en memoria viva todos los sorteos para evitar problemas si varias personas compran al mismo tiempo.
* **`start_link/1`**: Enciende el servidor.
* **`crear_sorteo/1`, `listar_sorteos/0`, `cerrar_sorteo/1`**: Son funciones "cliente" que le envían mensajes al servidor de fondo para que modifique los datos.
* **`comprar_fraccion/4`**: Coordina la validación de que un billete no se sobrevenda.
* **`handle_call` / `handle_cast`**: Son las funciones internas que "escuchan" los mensajes y actualizan el estado real de los sorteos en memoria y los guardan en disco.
* **`generar_ganadores/1`**: Lógica aleatoria que escoge billetes ganadores cuando el administrador cierra un sorteo.

### 7. `lib/azar/sorteo.ex` (`Azar.Sorteo`)
Define qué es un Sorteo.
* **`defstruct`**: Indica que un sorteo tiene ID, nombre, precio, fecha, billetes, estado y ganadores.
* **`precio_fraccion/1`**: Calcula cuánto cuesta un "pedacito" de billete dividiendo el costo total por la cantidad de fracciones.

### 8. `lib/azar/apuesta.ex` (`Azar.Apuesta`)
Maneja el registro histórico de las compras que hacen los jugadores.
* **`registrar_apuesta/5`**: Crea el registro de compra y lo guarda en `apuestas.json`.
* **`historial_por_jugador/1`**: Filtra el archivo JSON para devolver solo las compras de un jugador específico.

### 9. `lib/azar/billete.ex` (`Azar.Billete`)
Define el struct de un billete individual dentro de un sorteo.
* **`defstruct`**: Mantiene cuántas fracciones le quedan a un billete y quiénes lo han comprado.

### 10. `lib/azar/reportes.ex` (`Azar.Reportes`)
Se encarga de procesar los datos matemáticamente para el Administrador.
* **`reporte_ventas/1`**: Calcula cuánto dinero recaudó un sorteo específico.
* **`reporte_premios/0`**: Revisa los sorteos finalizados para listar quién ganó y cuánto.
* **`reporte_general/0`**: Suma de todo el sistema (dinero total, cantidad de usuarios).

### 11. `lib/azar/logger.ex` (`Azar.Logger`)
Bitácora de seguridad.
* **`registrar/2` / `registrar/3`**: Toma una acción (ej. "Inicio sesión") y la guarda en el archivo de texto `bitacora.txt` con la fecha y hora exactas.

### 12. `lib/azar/notificador.ex` y `suscripcion.ex`
Se encargan de la comunicación en tiempo real y bandeja de mensajes.
* **`Azar.Suscripcion.suscribir_jugador/1`**: Agrega al jugador a una lista de difusión.
* **`Azar.Notificador.enviar_notificacion_global/1`**: Avisa a todos los inscritos que hay un nuevo sorteo.
* **`Azar.Notificador.notificar_ganador/2`**: Le manda un mensaje directo a la bandeja del ganador felicitándolo.
* **`Azar.Notificador.obtener_notificaciones/1`**: Lee la bandeja de mensajes de un jugador desde el archivo JSON.

### 13. `lib/azar/servidor.ex` y `cliente.ex`
Manejan la Etapa 2 de "Sistemas Distribuidos". Permiten que el proyecto no corra en una sola computadora, sino que computadoras separadas se conecten.
* **`Azar.Servidor.iniciar/0`**: Levanta la aplicación central compartida.
* **`Azar.Cliente.conectar/1`**: Conecta una terminal de otra computadora a la base central usando el ecosistema de red de Erlang/Elixir.
