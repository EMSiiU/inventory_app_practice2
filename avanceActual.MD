# Avance actual de Inventory App

**Fecha de actualización:** 16 de octubre de 2026
**Base de referencia:** arquitectura y requerimientos de [`diseñoApp.md`](./diseñoApp.md).

## Resumen

La aplicación Flutter ya tiene navegación principal activa y flujos conectados para inventario, registro de artículos, calendario de caducidades, carrito de reposición y gestión de productos, categorías, tiendas, historial de movimientos y estadísticas en Gestión. SQLite conserva los datos localmente; el inventario calcula existencias desde los lotes y permite consumirlas en orden FEFO.

El avance es funcional, pero parcial frente al diseño: el escáner sigue siendo un marcador de posición, no hay búsqueda, las alarmas solo guardan una preferencia y faltan edición/detalle de productos.

## Arquitectura actual

```text
lib/
├── core/
│   ├── database/database_helper.dart
│   └── theme/app_theme.dart
├── data/
│   ├── models/
│   │   ├── category_model.dart
│   │   ├── product_batch_model.dart
│   │   ├── product_model.dart
│   │   └── store_model.dart
│   └── repositories/
│       ├── batch_repository.dart
│       ├── category_repository.dart
│       ├── product_repository.dart
│       ├── purchase_history_repository.dart
│       └── store_repository.dart
├── features/
│   ├── calendar/screens/calendar_screen.dart
│   ├── cart/
│   │   ├── cart_manager.dart
│   │   └── screens/cart_screen.dart
│   ├── inventory/screens/
│   │   ├── home_screen.dart
│   │   ├── inventory_screen.dart
│   │   └── new_item_screen.dart
│   └── settings/
│       ├── screens/
│       │   ├── manage_categories_screen.dart
│       │   ├── manage_products_screen.dart
│       │   ├── manage_store_screen.dart
│       │   ├── purchase_history_screen.dart
│       │   └── settings_screen.dart
│       └── widgets/
│           └── management_analytics_section.dart
├── shared/widgets/
│   ├── custom_sliver_app_bar.dart
│   ├── docked_navigation_bar.dart
│   └── product_card.dart
└── main.dart
```

`main.dart` inicia `HomeScreen`, que ofrece tres pestañas: Artículos, Calendario y Gestión. La pestaña de Escáner se retiró de la navegación mientras se define el flujo para capturar o seleccionar fotos durante el alta de un artículo. Búsqueda/trazabilidad tampoco está implementada todavía.

## Estado por funcionalidad

### Implementado

- **Tema y componentes:** tema oscuro con tipografía Inter, barra inferior translúcida, encabezados con efecto blur, tarjetas de productos y badge reactivo del carrito.
- **Inventario:** lectura de productos y stock calculado desde lotes; muestra nombres de categoría y última tienda. Las tarjetas permiten agregar al carrito o consumir una unidad.
- **Alta de artículo:** formulario con nombre, categoría, tienda, precio, fecha de caducidad, cantidad inicial, preferencia de alarma e imagen opcional, capturada con la cámara o elegida de la galería. La imagen se copia al almacenamiento privado persistente y su ruta se guarda en el producto. La categoría y la tienda se precargan con opciones predeterminadas cuando sus tablas están vacías (o, para categorías, tienen como máximo un registro).
- **Imagen en inventario:** las tarjetas muestran la imagen guardada del artículo y conservan el ícono predeterminado cuando no hay imagen o el archivo no está disponible.
- **Historial de movimientos:** combina compras y consumos en orden cronológico. Identifica el descuento de stock y señala explícitamente cuando un consumo deja el artículo agotado. Cada evento muestra la imagen del producto cuando está guardada; si no existe o no se puede cargar, conserva el ícono predeterminado.
- **Persistencia:** `DatabaseHelper` crea las tablas `Categoria`, `Tienda`, `Producto`, `Lote_Producto`, `Historial_Compras` e `Historial_Consumos`, con llaves foráneas e índices. La migración de la versión 1 a la 2 crea el historial de consumos sin eliminar datos; la versión 4 retira la columna experimental `Tienda.tipo`, conservando registros. El alta del producto y su lote inicial usa una transacción.
- **Consumo FEFO:** `ProductRepository` descuenta existencias de los lotes con fecha de caducidad más próxima y registra en la misma transacción la cantidad consumida y el stock restante.
- **Calendario:** muestra marcadores en días con lotes activos por caducar y un modal con el nombre del producto y las unidades restantes.
- **Carrito y compras:** agregar/quitar productos, editar cantidad, capturar precio y caducidad, seleccionar tienda y registrar lote, historial y última tienda.
- **Historial y compatibilidad:** la tabla de consumos registra movimientos posteriores a la migración; las compras históricas previas se conservan, pero no se reconstruyen consumos pasados.
- **Gestión:** creación y eliminación básica de categorías y tiendas; alta/eliminación de productos; consulta del historial unificado de movimientos.
- **Estadísticas en Gestión:** tarjetas para unidades consumidas por día en los últimos siete días, compras históricas agrupadas por nombre de tienda (unidades e importe con precios disponibles) y proporción de consumos agotados frente a parciales. Hay estados vacíos y espacio desplazable al final para evitar que la navegación inferior tape la gráfica.
- **Esquema de tiendas:** las estadísticas agrupan por el nombre existente de la tienda; no existe una clasificación de tiendas por tipo.

### Parcial o pendiente

- El estado de las tarjetas depende únicamente de existencias. La condición «próximo a caducar» no está conectada; el estado `warning` aún no se utiliza.
- El modal del calendario solo consulta y muestra los lotes: no ofrece acciones para consumirlos ni agregarlos al carrito. Los errores de carga se registran en consola, sin una vista de error dedicada.
- El carrito vive en memoria y no persiste al cerrar la aplicación. El checkout procesa artículos uno por uno: el lote y el historial se guardan en operaciones separadas y no hay una transacción única para toda la compra.
- La cantidad y el precio del checkout no tienen validación de formulario; valores que no se puedan convertir se sustituyen por valores predeterminados.
- La creación de artículo guarda producto y lote en una transacción, pero la escritura posterior del historial de compra queda fuera de ella.
- No hay edición ni detalle de productos. El stock mínimo se fija en `1`; no se capturan marca, UPC/código de barras ni código de lote en el formulario.
- El switch de alarma persiste `alarma_activa`, pero no hay programación de notificaciones locales.
- Escáner de códigos de barras y búsqueda/trazabilidad todavía no tienen flujos implementados; la dependencia `mobile_scanner` está declarada, pero no conectada a una pantalla.
- La base está en versión 4. La migración elimina la columna experimental `Tienda.tipo` sin modificar las tiendas, compras ni consumos existentes. La base del dispositivo se respaldó antes de ejecutar esa migración.

## Verificación realizada

Verificación local ejecutada con Flutter 3.47.1 y Dart 3.13.1:

- **Análisis focalizado:** `dart analyze` sobre los archivos de esta funcionalidad y su prueba, sin problemas.
- **Pruebas de widgets:** 5 pruebas pasan.
- **Android:** compilación e instalación correctas; hot restart exitoso y sin errores de ejecución reportados.
- **Migración de base de datos:** `PRAGMA integrity_check` devolvió `ok`, `PRAGMA foreign_key_check` no detectó problemas y los conteos de filas de todas las tablas se conservaron tras retirar `Tienda.tipo`.
- La consulta combinada de movimientos se ejecutó contra SQLite con datos de compra, consumo parcial y agotamiento; devolvió los tres eventos en orden cronológico.
- La validación visual automatizada de las gráficas en distintas dimensiones de pantalla queda pendiente.

## Próximos pasos sugeridos

1. **Estabilizar pruebas y análisis**
   - Preparar una base SQLite de prueba o aislar la carga de datos en pruebas de widgets.
   - Resolver los hallazgos de `flutter analyze`, empezando por declarar correctamente las dependencias directas.
2. **Cerrar integridad de compras**
   - Validar cantidad, precio y tienda antes del checkout.
   - Hacer transaccional la creación de lote e historial y evitar compras parcialmente guardadas al procesar varios artículos.
   - Definir si el carrito debe conservarse al reiniciar la aplicación.
3. **Completar la gestión de inventario**
   - Añadir detalle y edición del producto, stock mínimo configurable y los campos de marca, UPC y código de lote contemplados en el diseño.
   - Conectar lotes y fechas de caducidad al estado de las tarjetas y agregar las acciones de consumo/reposición al calendario.
4. **Completar secciones previstas**
   - Implementar y conectar el escáner y búsqueda/trazabilidad.
   - Implementar permisos, programación y cancelación de alarmas locales.
5. **Validar persistencia y plataformas**
   - Agregar pruebas de repositorios para transacciones, stock, FEFO, compras y restricciones de borrado.
   - Ejecutar compilación y pruebas en emulador/dispositivo para las plataformas objetivo.
   - Incorporar migraciones antes de evolucionar el esquema de base de datos.

## Criterio de avance

Considerar completa una funcionalidad cuando su interfaz, reglas de negocio y persistencia estén conectadas, sus casos esenciales estén probados y los errores tengan una respuesta visible. Los puntos descritos como parciales o pendientes no deben interpretarse como entregados.
