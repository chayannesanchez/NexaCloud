# 🌐 NexaCloud - Centro de Soporte Técnico
## 🎨 Identidad Visual - NexaCloud

### Colores Principales
- **Primario**: `#0066FF` - Azul corporativo
- **Secundario**: `#00D4FF` - Cyan vibrante
- **Fondo Oscuro**: `#0A1428` - Azul muy oscuro
- **Éxito**: `#10B981` - Verde
- **Advertencia**: `#F59E0B` - Ámbar
- **Peligro**: `#EF4444` - Rojo

### Tipografía
- **Familia**: Segoe UI, Tahoma, Geneva, Verdana, sans-serif
- **Peso**: 500 (normal), 600 (semibold), 700 (bold)

### Elementos de Diseño
- Logo con gradiente azul-cyan
- Íconos emoji integrados (☁️, 📋, ✅, etc.)
- Bordes redondeados suaves (0.5rem - 0.75rem)
- Sombras sutiles con hover effects
- Gradientes lineales en headers y botones

## 📄 Páginas del Sistema

### 1️⃣ **Inicio** (`index.html`)
**Propósito**: Página principal con introducción al sistema de soporte (entrypoint en root con redirección a `index/index.html`)

### 2️⃣ **Login** (`login/login.html`)
**Propósito**: Autenticación segura con AWS Cognito

### 3️⃣ **Formulario de Tickets** (`form/form.html`)
**Propósito**: Permitir a cualquiera crear tickets de soporte
**Autenticación**: ❌ **NO REQUERIDA** - Acceso público

### 4️⃣ **Panel de Control** (`support/support.html`)
**Propósito**: CRUD completo de tickets para equipo de soporte
**Autenticación**: ✅ **REQUERIDA** - Solo usuarios con Cognito
---

## 🎯 Estados de Tickets

| Estado | Color | Significado |
|--------|-------|------------|
| **Open** | Azul | Ticket abierto sin asignar |
| **In Progress** | Ámbar | Actualmente siendo trabajado |
| **Resolved** | Verde | Problema solucionado |
| **Closed** | Gris | Ticket cerrado/completado |

---

## ⚡ Niveles de Prioridad

| Prioridad | Color | Tiempo Respuesta |
|-----------|-------|-----------------|
| **Baja** | Verde | 48-72 horas |
| **Media** | Ámbar | 24-48 horas |
| **Alta** | Rojo | 2-4 horas |

---

## 🛠️ Mantenimiento

### Agregar Nueva Categoría
1. Editar `form.html` y `support.html`
2. Agregar opción en `category-options`
3. Actualizar `style.css` si necesario

### Cambiar Colores
1. Editar variables CSS en `style.css`
2. Buscar `:root { --primary-color: ... }`
3. Cambiar valores hexadecimales

### Agregar Nuevos Estados
1. Editar opciones en select `filterStatus`
2. Agregar badge CSS correspondiente
3. Actualizar lógica de filtro

---

## 🎓 Notas de Desarrollo

### Tecnologías Utilizadas
- HTML5
- CSS3 (Grid, Flexbox, Variables CSS)
- JavaScript ES6+ (eventos, DOM manipulation)

---

Made with ❤️ for **NexaCloud Support Team**


---

Para documentación completa del proyecto, consultar `../docs/` y `../README.md`.
