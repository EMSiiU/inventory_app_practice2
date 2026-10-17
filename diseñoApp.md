# Especificación de UI y Arquitectura Frontend: App de Alacena e Inventario Doméstico (iOS Native Dark Theme)

Este documento contiene el contexto completo, especificaciones de diseño visual (UI/UX), sistema de diseño estilo iOS nativo (Apple Human Interface Guidelines en Modo Oscuro), flujo de pantallas, modelo de datos relacional local y directrices para agentes de IA que implementarán la aplicación en **Flutter**.

---

## 1. Resumen Ejecutivo del Producto

Aplicación móvil orientada a la **gestión de inventario doméstico y alacena inteligente** para iOS/Android (desarrollada con Flutter). Resuelve el problema del desperdicio de comida y falta de provisiones aplicando gestión de caducidad estricta **FEFO (First Expired, First Out)**, trazabilidad de tiendas habituales y generación reactiva de listas de compra con sistema de badges interactivos.

---

## 2. Sistema de Diseño (iOS Native Dark Mode System Tokens)

Inspirado en las capturas de referencia (`item-lists-dark.png`, `items-dark.png`, `trends-dark.png`, `item-scanner-dark.png`, `item-dark.png`). La estética replica rigurosamente el estilo nativo de Apple (iOS 17/18 Human Interface Guidelines).

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
   - Contenedor con efecto vidrio líquido (`blur`) en la parte inferior con 4 pestañas:
     - 📦 **Artículos** (`CupertinoIcons.square_stack_3d_up_fill`)
     - 📑 **Listas / Alacena** (`CupertinoIcons.square_grid_2x2_fill`)
     - 🔍 **Buscar / Trazabilidad** (`CupertinoIcons.search`)
     - 📷 **Escáner** (`CupertinoIcons.barcode_viewfinder`)

---

## 3. Arquitectura de Pantallas y Requerimientos

### Pantalla 1: Listado Principal ("Artículos" / "Alacena")
* **Estructura**: `CustomScrollView` usando `SliverAppBar` expandible y `SliverList` / `SliverAnimatedList`.
* **Header / AppBar**:
  - Título grande "Artículos".
  - Botón superior izquierdo: modo vista / filtros rápidos.
  - Botón superior derecho: Icono de Carrito de Compras (`CupertinoIcons.cart_fill`) envuelto con paquete `badges: ^3.1.2` (`badges.Badge(badgeContent: Text('$cartCount'))`).
  - Botón superior derecho: Botón circular de añadir artículo (`+`).
* **Sección de Alertas Rápidas**:
  - Filtro horizontal o tarjetas destacadas para artículos **próximos a caducar** y **agotados / por agotarse**.
* **Ítem de Lista de Artículo**:
  - Miniatura o imagen del producto (redondeada, radio 12pt).
  - Nombre del producto y categoría (`SF Pro Text 16pt Semibold`).
  - Lote próximo a caducar (días restantes o fecha) y última tienda vinculada.
  - Indicador de estado por color (Rojo: Caducado/Agotado, Naranja: Por caducar, Verde: Óptimo).
  - Conteo de existencias en píldora circular (`2 UN`).
  - Botón de acción rápida: **"Añadir al Carrito"** (`+🛒`), que incrementa reactivamente el badge del header.

---

### Pantalla 2: Vista de Calendario de Caducidades (`table_calendar`)
* **Implementación con `table_calendar: ^3.1.2`**:
  - Estilo visual modo oscuro (`CalendarStyle` con fondos oscuros, textos blancos y círculos seleccionados en azul `#0A84FF`).
  - **Días con alertas de caducidad**:
    - Marcadores inferiores múltiples (puntos / dots) debajo del número del día (`eventLoader` que devuelve la lista de lotes/artículos que caducan esa fecha).
    - Cantidad de puntos = cantidad de alertas en ese día.
    - Color del punto codificado por criticidad (Rojo para caducados, naranja para ≤3 días).
* **Interacción Modal Full-Screen**:
  - Al hacer tap en un día específico: abrir un modal a pantalla completa (`showCupertinoModalPopup` o `Navigator.push` con transición fullscreen modal estilo iOS).
  - **Contenido del Modal**:
    - Botón de cierre ("Cerrar" o cruz translúcida) y fecha seleccionada en grande.
    - Listado completo de artículos que vencen dicho día: imagen, nombre, categoría, lote, stock disponible y tienda donde se compró.
    - Botón de acción por ítem: "Marcar como consumido" (descontar stock FEFO) o "Añadir a lista de compras".

---

### Pantalla 3: Registro y Edición de Artículo (CRUD con Integridad)
* **Formulario Agrupado Estilo iOS**:
  - Selector de Categoría (Desplegable / `CupertinoPicker` / Pills horizontales con iconos: Lácteos, Carnes, Despensa, Abarrotes, Limpieza, etc.).
  - Nombre del producto, marca, código de barras/UPC (con botón para invocar lector).
  - Stock mínimo de seguridad (umbral para lanzar alarma de "Por agotarse").
  - Switch para "Activar alarmas locales de caducidad" (`lanzar_alarma_local: true`).
* **Sub-sección de Lotes (`LoteProducto`)**:
  - Registro del lote inicial: Número de lote, fecha de caducidad (DatePicker iOS), cantidad de unidades y selección de la Tienda de compra.

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
* **Persistencia**:
  - Las compras se consultan desde `Historial_Compras`.
  - Los consumos se consultan desde `Historial_Consumos`.
  - Combinar ambas fuentes sin perder el tipo del movimiento y ordenarlas por fecha descendente.
  - Los movimientos de consumo se registran junto con el descuento de lotes en una misma transacción.

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
## Arquitectura Basada en Funcionalidades (Feature-First)
lib/
├── core/                   # Elementos globales e infraestructura de la app
│   ├── theme/
│   │   └── app_theme.dart  <-- UBICACIÓN DEL TEMA
│   ├── database/           # Configuración de SQLite (Tablas, llaves foráneas, índices)
│   └── utils/              # Constantes, formateadores de fecha, etc.
│
├── data/                   # Capa de datos (Lógica de negocio y modelos)
│   ├── models/             # Modelos (Categoria, Tienda, Producto, Lote_Producto y movimientos)
│   └── repositories/       # Controladores para las operaciones CRUD locales
│
├── features/               # Módulos divididos por funcionalidad
│   ├── inventory/          # Pantalla 1 y 3: Listado, Alacena, CRUD de artículos
│   │   ├── screens/        
│   │   ├── widgets/        # Tarjetas de artículos, pill badges circulares
│   │   └── controllers/    # Lógica para cálculo de estado Agotado y reglas FEFO[cite: 5]
│   │
│   ├── calendar/           # Pantalla 2: Vista de calendario de caducidades[cite: 5]
│   │   ├── screens/        # Modal Full-Screen de días específicos[cite: 5]
│   │   └── widgets/        
│   │
│   ├── cart/               # Pantalla 4: Carrito de compras y reposición[cite: 5]
│   │   ├── screens/        
│   │   └── controllers/    # Actualización de inventario e Historial_Compras[cite: 5]
│   ├── settings/           # Gestión y consulta del historial de movimientos
│   │   └── screens/        
│   │
│   └── trends/             # Pantalla 6: Trazabilidad y consumo[cite: 5]
│       └── screens/        
│
├── shared/                 # Widgets globales reutilizables en múltiples features
│   └── widgets/            # Ej. Docked Navigation Bar, Sliver Navigation Bar base[cite: 5]
│
└── main.dart               # Punto de entrada de la aplicación

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
5. **Registro de consumo y agotamiento**:
   - Al consumir unidades, descontarlas de los lotes activos en orden FEFO dentro de una transacción.
   - Registrar la cantidad efectivamente descontada y el stock total restante en `Historial_Consumos`, dentro de la misma transacción que actualiza los lotes.
   - Si no hay unidades disponibles, no crear un evento de consumo.
   - Determinar el agotamiento a partir de `stock_restante = 0`; un consumo que deja existencias positivas es parcial.

---

## 5. Esquema Relacional de Base de Datos Local (SQLite / Drift / Floor)

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
  - `mobile_scanner: ^5.1.1`: Para lectura de código de barras físico.

---