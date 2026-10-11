# Avance actual de Inventory App

**Fecha de actualización:** 11 de octubre de 2026  
**Base de referencia:** arquitectura y requerimientos de [`diseñoApp.md`](./diseñoApp.md).

## Resumen

La aplicación cuenta con una base Flutter organizada en tema, persistencia local SQLite, modelos, repositorios, widgets compartidos y pantallas de inventario. El flujo para registrar un artículo y su lote inicial está implementado y fue corregido para guardar ambos registros en una sola transacción. La interfaz todavía representa una parte del diseño: inventario y formulario son las pantallas funcionales principales; calendario, reposición, búsqueda, escáner, tendencias y notificaciones aún no están integrados como flujos completos.

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
├── features/inventory/screens/
│   ├── home_screen.dart
│   ├── inventory_screen.dart
│   └── new_item_screen.dart
├── shared/widgets/
│   ├── custom_sliver_app_bar.dart
│   ├── docked_navigation_bar.dart
│   └── product_card.dart
└── main.dart
```

La organización por funcionalidades está iniciada, pero los módulos `calendar`, `cart` y `trends` descritos en el diseño todavía no aparecen en `lib/`. La navegación inferior y `HomeScreen` existen, aunque `main.dart` actualmente abre directamente `InventoryScreen`; por ello, las pestañas aún no forman parte del flujo activo de la aplicación.

## Avances implementados

### Interfaz y tema

- Tema oscuro OLED con fondo negro, superficies oscuras, azul de acción y colores de estado definidos en `AppTheme`.
- Inter se aplica globalmente mediante `GoogleFonts.inter()`.
- Encabezado de inventario con título grande, botón para añadir y acceso visual al carrito.
- Tarjetas de producto con nombre, estado de existencias, cantidad y acciones deslizables.
- Formulario de nuevo artículo con nombre, fecha de caducidad, cantidad inicial y switch de alarmas.
- Formulario ajustado para mantener campos agrupados, permitir desplazamiento con el teclado abierto y mostrar errores de guardado.

### Persistencia y reglas de inventario

- `DatabaseHelper` configura SQLite y crea las tablas `Categoria`, `Tienda`, `Producto`, `Lote_Producto` e `Historial_Compras`, con llaves foráneas e índices.
- Los modelos representan categorías, tiendas, productos y lotes.
- Los repositorios incluyen operaciones para leer e insertar productos, lotes, categorías y tiendas.
- Al crear un artículo, se garantiza que exista una categoría válida; si la base no tiene categorías, se crea «Despensa».
- El artículo y su lote inicial se insertan dentro de una transacción: si una inserción falla, no queda un registro parcial.
- El inventario calcula el total de unidades desde los lotes activos.
- El consumo de unidades recorre lotes ordenados por fecha de caducidad (FEFO).
- Existe un repositorio capaz de registrar una compra y actualizar la última tienda del producto, aunque todavía no está conectado a una pantalla de compra.

### Verificación reciente

- Las dos pruebas de widgets del formulario pasan: comprobación de campos agrupados y validación de entradas requeridas.
- El análisis de los archivos Dart modificados no encontró problemas.
- La compilación Android de depuración generó el APK correctamente.
- No se ha confirmado todavía el flujo en un teléfono físico.

## Pendientes respecto al diseño

- El selector de categoría no está en el formulario. Al guardar se utiliza la categoría existente de menor ID o se crea «Despensa» si no hay ninguna.
- No se capturan marca, UPC/código de barras, stock mínimo configurable, código de lote ni tienda de compra en el formulario.
- La lista muestra identificadores de categoría y tienda, no sus nombres legibles.
- La detección de productos próximos a caducar está pendiente; el estado de las tarjetas actualmente se deriva del stock.
- El ícono de carrito no abre una pantalla y su contador está fijo en cero.
- Las pestañas de alacena, búsqueda y escáner no están conectadas a pantallas funcionales.
- El switch guarda el indicador de alarma en el producto, pero todavía no se programan notificaciones locales.
- No hay pantallas de detalle o edición de producto implementadas.
- El esquema de base de datos está en versión 1 y aún no tiene un flujo de migración para futuras modificaciones.

## Próximos pasos sugeridos

Los pasos están ordenados para completar las capas de datos y conectar después sus pantallas. Se enfocan en los componentes contemplados en el diseño actual.

1. **Completar el flujo de inventario (`features/inventory`)**
   - Mostrar nombres de categoría y tienda en vez de sus IDs.
   - Integrar la consulta de lotes con la lista para calcular estados de caducidad y alertas.
   - Terminar el formulario con selector de categoría y los campos de lote/tienda que define `diseñoApp.md`.
   - Añadir las pantallas de detalle y edición para completar el CRUD previsto.

2. **Activar la navegación (`main.dart`, `HomeScreen` y `shared/widgets`)**
   - Decidir la composición de las cuatro pestañas del diseño y conectarla desde `main.dart`.
   - Enlazar cada pestaña solo cuando su pantalla correspondiente esté implementada.

3. **Implementar calendario (`features/calendar`)**
   - Crear la vista de calendario y conectar `BatchRepository.getBatchesExpiringOnDate`.
   - Mostrar lotes que vencen en la fecha seleccionada y reutilizar la lógica FEFO para consumir unidades.

4. **Implementar carrito y reposición (`features/cart`)**
   - Definir cómo persistir los artículos seleccionados para reposición antes de construir su interfaz.
   - Conectar la compra completada con la creación del lote y `PurchaseHistoryRepository`.
   - Verificar que la última tienda y el historial se actualicen de forma consistente.

5. **Implementar búsqueda, tendencias y escáner**
   - Crear las pantallas planeadas para búsqueda/trazabilidad y gráficos a partir del historial de compras.
   - Conectar el flujo de escaneo a la dependencia `mobile_scanner` ya declarada y al formulario existente.

6. **Completar alarmas locales**
   - Definir permisos, programación y cancelación de notificaciones según el indicador de alarma guardado.
   - Probar el comportamiento en Android físico además de emulador.

7. **Ampliar validación automatizada**
   - Añadir pruebas de repositorios con una base SQLite de prueba para inserciones, transacciones, stock y FEFO.
   - Añadir pruebas de navegación y formularios conforme se conecten las pantallas.
   - Verificar los flujos en emulador y teléfono físico antes de considerar cerrada la compatibilidad móvil.

## Criterio de avance

Cada módulo debe quedar conectado de extremo a extremo —interfaz, repositorio y persistencia— y contar con pruebas del comportamiento esencial antes de considerarse completo. Las funciones descritas en “Próximos pasos” son trabajo pendiente; no se deben interpretar como funcionalidades ya entregadas.
