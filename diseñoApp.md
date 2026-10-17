# Especificación de UI y Arquitectura Frontend: App de Alacena e Inventario Doméstico (iOS Native Dark Theme)

Este documento contiene el contexto completo, especificaciones de diseño visual (UI/UX), sistema de diseño estilo iOS nativo (Apple Human Interface Guidelines en Modo Oscuro), flujo de pantallas, modelo de datos relacional local y directrices para agentes de IA que implementarán la aplicación en **Flutter**.

---

## 1. Resumen Ejecutivo del Producto

Aplicación Flutter para Android/iOS orientada a la **gestión de inventario doméstico y alacena inteligente**. Resuelve el problema del desperdicio de comida y la falta de provisiones aplicando gestión de caducidad **FEFO (First Expired, First Out)**, historial de compras y consumos, y generación reactiva de una lista de reposición.

> Este documento reúne la dirección de diseño y el estado funcional vigente. Los detalles de lo que aún no está implementado se indican en cada sección. La guía técnica basada en el código está en [`guia.md`](./guia.md).

---

## 2. Sistema de Diseño (iOS Native Dark Mode System Tokens)

Inspirado en capturas de referencia de listas, artículos e indicadores. La estética replica el estilo nativo de Apple (iOS 17/18 Human Interface Guidelines).

### 2.1 Paleta de Color Tokens (Dark Theme OLED)

| Token Semántico | Valor Hex / RGBA | Uso en Flutter (`ThemeData` / `CupertinoThemeData`) |
| :--- | :--- | :--- |
| `color-bg-canvas` | `#000000` | Fondo raíz de pantallas y scaffolds (True Black OLED) |
| `color-surface-card` | `#1C1C1E` | Tarjetas agrupadas, contenedores secundarios (iOS Secondary System Background) |
| `color-surface-elevated` | `#2C2C2E` | Modales, bottom sheets, campos de texto y pickers |
| `color-surface-pill` | `#2C2C2E` / `#3A3A3C` | Badges de conteo redondeados, filtros activos |
| `color-border-separator`| `#38383A` (o `#545458` al 35%) | Divisores sutiles de listas (`CupertinoListTile.border`) |
| `color-text-primary` | `#FFFFFF` | Títulos grandes, nombres de productos |
| `color-text-secondary` | `#8E8E93` | Categorías, tiendas, subtítulos descriptivos |
| `color-accent-blue` | `#0A84FF` | Botones de acción, enlaces ("Ver todos", "Ajustar Stock", tabs activos) |
| `color-status-expired` | `#FF453A` (Rojo iOS) | Alerta crítica: Lote caducado, sin stock (Agotado) |
| `color-status-warning` | `#FF9F0A` (Naranja iOS) | Próximo a caducar (≤ 3 días) |
| `color-status-low` | `#FFD60A` (Amarillo iOS) | Stock bajo / por agotarse |
| `color-status-good` | `#30D158` (Verde iOS) | Stock óptimo / vigente / entradas de inventario |
| `color-badge-accent` | `#FF2D55` (Rosa Neón iOS) | Conteo de favoritos y badges en listas |
| `color-badge-blue` | `#0A84FF` | Conteo de "En Stock" |

### 2.2 Tipografía (Inter)

* **Large Title**: `Inter`, 34pt, Bold, Tracking: -0.4px (Encabezados de sliver: "Artículos", "Listas", "Alacena")
* **Title 2**: `Inter`, 22pt, Bold, Tracking: -0.26px (Secciones en modal / títulos de tarjetas)
* **Title 3 / Card Headline**: `Inter`, 17pt, Semibold (Nombre del producto)
* **Subhead**: `Inter`, 14pt, Regular / Medium, Color: `#8E8E93` (Categoría, precio, fecha de caducidad)
* **Footnote / Caption**: `Inter`, 12pt, Regular, Tracking: +0.2px (UPC, código de lote, badges numéricos)
* **Button / Action**: `Inter`, 16pt, Semibold

### 2.3 Componentes y Patrones UI

1. **Sliver Navigation Bar con Gran Título (`CustomScrollView` + `SliverAppBar`)**:
   - Barra translúcida con blur (`BackdropFilter` con `sigmaX: 20`, `sigmaY: 20`).
   - Botones circulares translúcidos (`CircleAvatar(backgroundColor: Color(0xFF1C1C1E))`) para acciones superiores (e.g. `+`, `...`, carrito de compra con badge).
2. **Pill Badges Circulares de Existencias**:
   - Elemento distintivo visto en la UI: círculo gris oscuro/negro con la cantidad total o badge circular en la esquina superior derecha (`Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C2C2E)))`).
3. **Indicador Rápido de Estatus**:
   - Tag o micro-icono junto a la miniatura del producto con indicador de color:
     - 🔴 **Caducado**: Círculo rojo / icono reloj con alerta.
     - 🟠 **Por caducar**: Tag naranja con fecha resaltada.
     - ⚪ **Agotado**: Badge en 0 con color atenuado.
     - 🟢 **En orden**: Estatus normal con conteo positivo.
4. **Docked Navigation Bar (Tab Bar Flotante/Nativa)**:
   - La navegación implementada usa una barra translúcida con 3 pestañas:
     - 📦 **Artículos** (`CupertinoIcons.square_stack_3d_up_fill`)
     - 📅 **Calendario** (`CupertinoIcons.calendar`)
     - ⚙️ **Gestión** (`CupertinoIcons.gear`)
   - El acceso al carrito y al registro de artículos está en los controles superiores de Artículos. La búsqueda está integrada en esa pantalla.

---

## 3. Arquitectura de Pantallas y Requerimientos

### Pantalla 1: Listado Principal ("Artículos" / "Alacena")
* **Estructura**: `CustomScrollView` usando `SliverAppBar` expandible y `SliverList` / `SliverAnimatedList`.
* **Header / AppBar**:
  - Título grande "Artículos".
  - Accesos superiores para el carrito y para registrar un artículo.
* **Búsqueda y filtros implementados**:
  - Búsqueda por nombre sin distinguir mayúsculas y con espacios externos ignorados.
  - Filtros por categoría y estado: todos, en stock, stock bajo o agotados.
  - Orden por nombre A-Z, stock menor a mayor o stock mayor a menor.
* **Ítem de Lista de Artículo**:
  - Miniatura o imagen del producto (redondeada, radio 12pt).
  - Nombre del producto y categoría (`SF Pro Text 16pt Semibold`).
  - Muestra la categoría, última tienda y existencias agregadas de lotes activos.
  - El estado de tarjeta usa existencias y stock de seguridad; todavía no clasifica visualmente por próxima caducidad.
  - Conteo de existencias en píldora circular (`2 UN`).
  - Botón de acción rápida: **"Añadir al Carrito"** (`+🛒`), que incrementa reactivamente el badge del header.

---

### Pantalla 2: Vista de Calendario de Caducidades (`table_calendar`)
* **Implementación con `table_calendar: ^3.1.2`**:
  - Estilo visual modo oscuro (`CalendarStyle` con fondos oscuros, textos blancos y círculos seleccionados en azul `#0A84FF`).
  - **Días con alertas de caducidad**:
    - Marcadores inferiores múltiples (puntos / dots) debajo del número del día (`eventLoader` que devuelve la lista de lotes/artículos que caducan esa fecha).
    - Cantidad de puntos = cantidad de alertas en ese día.
    - Los lotes activos se marcan actualmente con puntos naranjas; el color no codifica criticidad individual.
* **Interacción implementada**:
  - Al seleccionar un día se abre un panel inferior desplazable con los lotes y cantidades activas que caducan ese día.
  - La vista actual no ofrece acciones de consumo/reabastecimiento ni detalle de imagen, categoría o tienda en el panel.
* **Mejora futura**: acciones rápidas para consumir o agregar a la lista de reposición.

---

### Pantalla 3: Registro y Edición de Artículo (CRUD con Integridad)
* **Formulario implementado**:
  - Nombre, categoría, tienda, precio unitario, cantidad y caducidad para el lote inicial; foto opcional tomada con cámara o seleccionada de la galería.
  - Switch `alarma_activa` para habilitar recordatorios locales de caducidad.
  - El stock mínimo se fija actualmente en 1. Marca y código de lote no se capturan en este formulario.
* **Mejora futura**: edición de productos y stock mínimo configurable.

---

### Pantalla 4: Carrito de Compras / Lista de Reposición
* **Acceso**: Mediante el icono con badge en la barra superior.
* **Funcionalidad**:
  - Lista de productos seleccionados para reabastecimiento.
  - Muestra la última tienda donde se adquirió (`ultima_tienda_id`) para optimizar el viaje de compra.
  - Al completar la compra: actualiza automáticamente el inventario creando un nuevo lote e insertando el registro en `Historial_Compras`.

---

### Pantalla 5: Historial de movimientos de inventario
* **Acceso**: Desde Gestión, en la opción "Historial de Movimientos".
* **Contenido**:
  - Cronología descendente de compras y consumos de productos.
  - Cada movimiento muestra producto, imagen (o ícono predeterminado), cantidad y fecha.
  - Las compras muestran tienda y precio unitario.
  - Los consumos muestran las unidades descontadas y las existencias resultantes.
  - Si el stock resultante es cero, identificar el movimiento como producto agotado; si queda stock, identificarlo como consumo parcial.
* **Persistencia implementada**:
  - Las compras se consultan desde `Historial_Compras`.
  - Los consumos se consultan desde `Historial_Consumos`.
  - Combinar ambas fuentes sin perder el tipo del movimiento y ordenarlas por fecha descendente.
  - Los movimientos de consumo se registran junto con el descuento de lotes en una misma transacción. Compra e historial de compra se escriben en una transacción; la creación del lote del checkout es una operación separada.

---

### Pantalla 6: Trazabilidad de Tiendas y Estadísticas ("Tendencias")
* Inspirada en `trends-dark.png`.
* En Gestión, debajo de "Historial de Movimientos", presentar tres tarjetas de estadísticas con estilo oscuro iOS:
  - Gráfico de consumo diario de unidades en los últimos siete días, sin selector mensual.
  - Desglose histórico por nombre de tienda, con unidades compradas y gasto sumado desde los precios unitarios disponibles.
  - Gráfico proporcional de consumos que agotaron el stock frente a consumos parciales, calculado desde `stock_restante`.
* Las tarjetas muestran estados vacíos cuando aún no hay registros. Los precios ausentes no se contabilizan como gasto.
* La tarjeta de agotamiento debe tener espacio de desplazamiento bajo ella para que la barra de navegación inferior no oculte la gráfica.
* Las tiendas se identifican por su nombre; no se mantiene una clasificación adicional por tipo.

---
## Arquitectura implementada (Feature-First)
```text
lib/
├── core/
│   ├── database/database_helper.dart
│   ├── notifications/expiration_notification_service.dart
│   └── theme/app_theme.dart
├── data/
│   ├── models/             # Producto, lote, categoría y tienda
│   └── repositories/       # Consultas y escrituras en SQLite
├── features/
│   ├── inventory/screens/  # Inicio, inventario y alta de artículo
│   ├── calendar/screens/   # Calendario de lotes
│   ├── cart/               # Estado temporal del carrito y checkout
│   └── settings/           # Gestión, historial y gráficas
├── shared/widgets/         # Tarjetas, barras y componentes compartidos
└── main.dart
```

--
## 4. Reglas de Negocio Implementadas

1. **Gestión de Caducidad FEFO (First Expired, First Out)**:
   - Al descontar unidades de un producto: ordenar lotes activos (`cantidad > 0`) por `fecha_caducidad ASC`.
   - Restar stock prioritariamente del lote cuya fecha sea menor. Si la cantidad a descontar supera el lote, agotar dicho lote y continuar con el siguiente.
2. **Estado Agotado**:
   - `stock_total = SUM(lotes.cantidad) WHERE producto_id = ? AND cantidad > 0`.
   - Si `stock_total == 0` o no hay lotes asociados, el producto pasa a `estado = 'Agotado'`.
3. **Trazabilidad de Tiendas**:
   - Al registrar una compra en `Historial_Compras(producto_id, tienda_id, fecha, cantidad, precio)`:
   - Se actualiza automáticamente `Producto.ultima_tienda_id = tienda_id`.
   - Permite consultar `SELECT DISTINCT Tienda.* FROM Tienda JOIN Historial_Compras ...` para el histórico global.
4. **Alarmas Locales**:
   - El campo booleano `alarma_activa` habilita una notificación local por cada lote activo, programada para las 9:00 a. m. (hora local) del mismo día de caducidad.
   - Las notificaciones se solicitan al guardar un artículo o registrar una compra; se cancelan al agotarse/eliminar el lote y se reconcilian con SQLite al iniciar la aplicación.
   - Si las 9:00 a. m. ya pasaron en la fecha de caducidad, no se programa una notificación retroactiva. Android usa alarmas inexactas; la pantalla "Probar alarma" es solo debug. La prueba real se ejecutó en un dispositivo Android; iOS necesita verificación en dispositivo Apple.
5. **Registro de consumo y agotamiento**:
   - Al consumir unidades, descontarlas de los lotes activos en orden FEFO dentro de una transacción.
   - Registrar la cantidad efectivamente descontada y el stock total restante en `Historial_Consumos`, dentro de la misma transacción que actualiza los lotes.
   - Si no hay unidades disponibles, no crear un evento de consumo.
   - Determinar el agotamiento a partir de `stock_restante = 0`; un consumo que deja existencias positivas es parcial.

---

## 5. Esquema Relacional de Base de Datos Local (SQLite mediante sqflite)

```sql
-- 1. Tabla de Categorías
CREATE TABLE Categoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    icono TEXT,
    color_hex TEXT
);

-- 2. Tabla de Tiendas
CREATE TABLE Tienda (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    ubicacion TEXT,
    icono TEXT
);

-- 3. Tabla de Productos
CREATE TABLE Producto (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    categoria_id INTEGER NOT NULL,
    imagen_url TEXT,
    stock_seguridad INTEGER DEFAULT 1,
    ultima_tienda_id INTEGER,
    alarma_activa INTEGER DEFAULT 1, -- Para notificaciones locales
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE RESTRICT,
    FOREIGN KEY (ultima_tienda_id) REFERENCES Tienda(id) ON DELETE SET NULL
);

-- 4. Tabla de Lotes (Soporte FEFO)
CREATE TABLE Lote_Producto (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id INTEGER NOT NULL,
    codigo_lote TEXT,
    fecha_caducidad DATE NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad >= 0),
    tienda_id INTEGER,
    FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
    FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE SET NULL
);

-- 5. Tabla de Histórico de Compras (Trazabilidad)
CREATE TABLE Historial_Compras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id INTEGER NOT NULL,
    tienda_id INTEGER NOT NULL,
    fecha_compra DATETIME DEFAULT CURRENT_TIMESTAMP,
    cantidad INTEGER NOT NULL,
    precio_unitario REAL,
    FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
    FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE RESTRICT
);

-- 6. Tabla de Histórico de Consumos de Inventario
CREATE TABLE Historial_Consumos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id INTEGER NOT NULL,
    fecha_consumo DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    stock_restante INTEGER NOT NULL CHECK (stock_restante >= 0),
    FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE
);

-- Índices clave para optimización de queries FEFO y Calendario
CREATE INDEX idx_lote_caducidad ON Lote_Producto(fecha_caducidad, cantidad);
CREATE INDEX idx_producto_categoria ON Producto(categoria_id);
CREATE INDEX idx_historial_consumos_fecha ON Historial_Consumos(fecha_consumo);
```

---

## 6. Paquetes Flutter Recomendados y Widgets Mandatorios

* **`table_calendar: ^3.1.2`**: Calendario con marcadores para caducidades por día.
* **`badges: ^3.1.2`**: Badge interactivo sobre el icono de carrito en el app bar superior.
* **Slivers obligatorios**:
  - `CustomScrollView`
  - `SliverAppBar` (con `largeTitle` o título expandible estilo iOS)
  - `SliverList` / `SliverGrid` / `SliverToBoxAdapter`
* **Widgets adicionales agregados (Diferenciadores)**:
  - `CupertinoSlidableAction` / `flutter_slidable: ^3.1.1`: Gestos swipe estilo iOS en cada artículo (descontar rápido, mandar a carrito).
  - `shimmer: ^3.0.0`: Efectos de carga esquelética oscura.
  - `fl_chart: ^0.68.0`: Para la pantalla de tendencias y gráficos de consumo.

---