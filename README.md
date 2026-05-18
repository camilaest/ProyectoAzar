# 🎰 Azar S.A. — Sistema de Sorteos y Apuestas

Sistema de gestión de sorteos distribuido desarrollado en **Elixir**, con soporte para múltiples nodos, concurrencia segura mediante el modelo de actores, persistencia en JSON y menús interactivos de consola.

---

## 📋 Tabla de contenido

- [Descripción general](#descripción-general)
- [Arquitectura del sistema](#arquitectura-del-sistema)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Ejecución](#ejecución)
- [Uso del sistema](#uso-del-sistema)
- [Módulos del proyecto](#módulos-del-proyecto)
- [Pruebas unitarias](#pruebas-unitarias)
- [Modo distribuido](#modo-distribuido)
- [Bitácora del sistema](#bitácora-del-sistema)
- [Persistencia de datos](#persistencia-de-datos)
- [Licencia](#licencia)

---

## Descripción general

Azar S.A. simula un sistema de lotería con tres roles:

- **Administrador** — crea y cierra sorteos, consulta estados, genera reportes y se conecta a nodos remotos.
- **Jugador** — se registra, inicia sesión, compra billetes o fracciones, consulta su historial y verifica premios.
- **Servidor central** — GenServer que serializa todas las operaciones de sorteo garantizando que dos jugadores nunca puedan comprar la misma fracción simultáneamente.

---

## Arquitectura del sistema

```
ProyectoAzar/
├── lib/
│   ├── azar/
│   │   ├── application.ex       # Supervisor principal (SorteoServer + Notificador)
│   │   ├── sorteo.ex            # Struct y lógica de negocio de sorteos
│   │   ├── sorteo_server.ex     # GenServer central (concurrencia y persistencia)
│   │   ├── apuesta.ex           # Struct y lógica de apuestas
│   │   ├── billete.ex           # Struct y lógica de billetes/fracciones
│   │   ├── jugador.ex           # Struct, CRUD y persistencia de jugadores
│   │   ├── menu_admin.ex        # Menú interactivo del administrador
│   │   ├── menu_jugador.ex      # Menú interactivo del jugador
│   │   ├── reportes.ex          # Generación de reportes en consola
│   │   ├── logger.ex            # Bitácora con niveles :info :warning :error
│   │   ├── azar_notificador.ex  # GenServer de notificaciones en tiempo real
│   │   └── azar_suscripcion.ex  # Suscripción de jugadores a notificaciones
│   ├── estructura.ex            # Menú principal del sistema
│   └── util.ex                  # Helpers de I/O y parsing
├── test/
│   ├── sorteo_test.exs          # Pruebas unitarias de Sorteo
│   ├── apuesta_test.exs         # Pruebas unitarias de Apuesta
│   ├── jugador_test.exs         # Pruebas unitarias de Jugador
│   └── azarConcurrenciaTest.exs # Pruebas de concurrencia
├── sorteos/                     # JSONs persistidos de cada sorteo
├── lib/bitacora.txt             # Bitácora del sistema
├── jugadores.json               # Base de datos de jugadores
└── apuestas.json                # Base de datos de apuestas
```

---

## Requisitos

- [Elixir](https://elixir-lang.org/install.html) **~> 1.19**
- [Erlang/OTP](https://www.erlang.org/) (se instala junto con Elixir)

Verifica tu instalación:

```bash
elixir --version
```

---

## Instalación

1. Clona el repositorio:

```bash
git clone <url-del-repositorio>
cd ProyectoAzar
```

2. Instala las dependencias:

```bash
mix deps.get
```

Las dependencias del proyecto son:
- `jason ~> 1.0` — serialización/deserialización JSON
- `tzdata ~> 1.1` — soporte de zona horaria para Colombia (America/Bogota)

3. Compila el proyecto:

```bash
mix compile
```

---

## Ejecución

### Modo normal (un solo nodo)

```bash
iex -S mix
```

Una vez dentro del shell interactivo de Elixir, inicia el menú principal:

```elixir
Estructura.menu_principal()
```

Verás:

```
══════════════════════════════════
      AZAR S.A. - Sorteos
══════════════════════════════════

1. Ingresar como Administrador
2. Ingresar como Jugador
3. Salir
```

### Modo distribuido (múltiples nodos)

Ver la sección [Modo distribuido](#modo-distribuido) más abajo.

---

## Uso del sistema

### Como Administrador

Al seleccionar la opción **1** desde el menú principal se accede al menú de administrador:

```
1. Crear nuevo sorteo          → Define nombre, precio, fracciones y premios
2. Listar sorteos              → Muestra todos los sorteos con su estado
3. Filtrar sorteos             → Filtra por estado: pendiente / realizado / todos
4. Consultar estado de sorteo  → Detalle completo de un sorteo por ID
5. Cerrar sorteo               → Genera ganadores aleatorios y finaliza el sorteo
6. Generar reportes            → Submenú con tres tipos de reporte
7. Conectarse como nodo remoto → Conecta este nodo a otro nodo Erlang en red
8. Volver al menú principal
```

#### Crear un sorteo

Al crear un sorteo se pedirá:
- **Nombre** del sorteo (texto libre)
- **Precio del billete** (entero, en pesos)
- **Cantidad de fracciones** por billete (mínimo 1)
- **Cantidad de billetes** totales
- **Premios** separados por coma (ej: `Primer Premio, Segundo Premio, Tercer Premio`)

#### Reportes disponibles

| Reporte | Descripción |
|---|---|
| Ventas por sorteo | Total recaudado, billetes y fracciones vendidas |
| Premios entregados | Qué billete ganó, qué premio y a qué jugador pertenece |
| Reporte general | Resumen global: sorteos, finanzas y jugadores activos |

---

### Como Jugador

Al seleccionar la opción **2** desde el menú principal se accede al menú de jugador:

```
1. Registrarse      → Crea una cuenta nueva
2. Iniciar sesión   → Autentica con identificación y contraseña
```

Después de iniciar sesión:

```
1. Ver sorteos disponibles    → Lista los sorteos en estado pendiente
2. Comprar billete/fracción   → Selecciona sorteo, billete y cantidad de fracciones
3. Ver mi historial           → Todas tus apuestas con monto total gastado
4. Ver mis premios ganados    → Cruza tus billetes con los ganadores de cada sorteo
5. Cerrar sesión
```

---

## Módulos del proyecto

| Módulo | Responsabilidad |
|---|---|
| `Azar.SorteoServer` | GenServer central. Serializa operaciones, garantiza concurrencia segura |
| `Azar.Sorteo` | Struct del sorteo. Lógica de creación, billetes y selección de ganadores |
| `Azar.Apuesta` | Struct de apuesta. Persistencia en `apuestas.json`, historial, total gastado |
| `Azar.Billete` | Struct del billete. Registro de compras por fracción |
| `Azar.Jugador` | Struct del jugador. CRUD, autenticación, persistencia en `jugadores.json` |
| `Azar.Reportes` | Tres tipos de reporte con formato de tabla en consola |
| `Azar.Logger` | Bitácora con niveles `:info`, `:warning`, `:error` y colores en consola |
| `Azar.Notificador` | GenServer de notificaciones en tiempo real para jugadores suscritos |
| `Azar.MenuAdmin` | Menú interactivo del administrador |
| `Azar.MenuJugador` | Menú interactivo del jugador con manejo de sesión |
| `Estructura` | Menú principal que enruta a administrador o jugador |

---

## Pruebas unitarias

Ejecuta todas las pruebas:

```bash
mix test
```

Ejecuta solo un archivo específico:

```bash
mix test test/sorteo_test.exs
mix test test/apuesta_test.exs
mix test test/jugador_test.exs
```

Ejecuta con detalle de cada prueba:

```bash
mix test --trace
```

### Cobertura de pruebas

| Módulo | Pruebas |
|---|---|
| `Azar.Sorteo` | Creación, generación de billetes, IDs únicos, premios como string y lista, selección de ganadores, verificación de ganador |
| `Azar.Apuesta` | Creación con campos correctos, IDs únicos, estado por defecto, fecha, historial por jugador, total gastado |
| `Azar.Jugador` | Creación, caracteres especiales, validación de duplicados, campos vacíos, carga de archivo inexistente |
| Concurrencia | Compras simultáneas sobre el mismo billete, atomicidad del GenServer |

---

## Modo distribuido

El sistema puede ejecutarse con múltiples nodos Erlang conectados entre sí. El nodo servidor centraliza los sorteos; los nodos cliente se conectan para operar como administrador o jugador remoto.

### Levantar el nodo servidor

```bash
iex --sname servidor --cookie azar_cookie -S mix
```

Dentro del shell:

```elixir
Estructura.menu_principal()
```

### Conectar un nodo cliente

En otra terminal (otra máquina o la misma):

```bash
iex --sname cliente1 --cookie azar_cookie -S mix
```

Dentro del shell, conéctate al servidor:

```elixir
Node.connect(:"servidor@nombre-del-host")
```

O usa la opción **7** del menú administrador → **"Conectarse como nodo remoto"** e ingresa el nombre del nodo (ej: `servidor@192.168.1.10`).

### Verificar nodos conectados

```elixir
Node.list()
```

### Consideraciones para la conexión

- Ambos nodos deben usar el **mismo cookie** (`--cookie azar_cookie`).
- Si los nodos están en máquinas distintas, deben estar en la **misma red** o tener acceso entre ellas.
- El puerto por defecto de distribución de Erlang es **4369** (epmd). Asegúrate de que no esté bloqueado por el firewall.
- El nombre del nodo sigue el formato `nombre@host`, donde `host` puede ser el nombre de la máquina o su IP.

---

## Bitácora del sistema

Todas las operaciones relevantes quedan registradas en `lib/bitacora.txt` con el siguiente formato:

```
[INFO]    2026-05-18 14:32:05 - SorteoServer - Crear sorteo - OK - ID: 599088
[INFO]    2026-05-18 14:33:01 - SorteoServer - Compra fracción - Jugador: 123 - Sorteo: 599088 - Billete: 005 - OK - Apuesta ID: a3f1c8b2
[WARNING] 2026-05-18 14:33:45 - SorteoServer - Compra fracción - ERROR: El sorteo ya no está disponible
[ERROR]   2026-05-18 14:34:10 - SorteoServer - Finalizar sorteo - ERROR: Sorteo no encontrado
```

| Nivel | Cuándo se usa |
|---|---|
| `[INFO]` | Operaciones exitosas: crear sorteo, comprar fracción, finalizar sorteo |
| `[WARNING]` | Rechazos de negocio: sorteo no encontrado, billete sin fracciones, apuesta ya devuelta |
| `[ERROR]` | Fallos graves o inesperados del sistema |

En consola los mensajes aparecen con color: verde para info, amarillo para warning y rojo para error.

---

## Persistencia de datos

El sistema persiste toda su información en archivos JSON locales:

| Archivo | Contenido |
|---|---|
| `sorteos/sorteo_<id>.json` | Un archivo por cada sorteo creado |
| `jugadores.json` | Lista de todos los jugadores registrados |
| `apuestas.json` | Lista de todas las apuestas realizadas |
| `priv/notificaciones.json` | Historial de notificaciones por jugador |
| `lib/bitacora.txt` | Bitácora de operaciones del sistema |

Al reiniciar el servidor, los sorteos se recargan automáticamente desde el directorio `sorteos/`.

---

## Integrantes

- Natalia
- Michael Joel Alvarez Gil
- Camila
- Juan

---

## Licencia

GNU GPL v3 — Mayo del 2026
