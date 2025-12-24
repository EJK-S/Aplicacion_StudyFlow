# 🎓 StudyFlow

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-NoSQL-orange?style=for-the-badge)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-green?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)

> **Tu compañero académico integral.** Centraliza la gestión de notas, automatiza formatos repetitivos y mantén el control de tu semestre.

---

## 📥 Descarga Directa (Windows)

¿Quieres probar la app sin compilar código? Descarga el instalador oficial para Windows:

👉 **[Descargar StudyFlow v1.0 para Windows](https://github.com/EJK-S/Aplicacion_StudyFlow/releases/latest)**

---

## 📱 Descripción del Proyecto

**StudyFlow** es una aplicación multiplataforma (Móvil & Desktop) diseñada para estudiantes universitarios que necesitan más que una simple agenda. El proyecto nace de la necesidad de centralizar la gestión académica y automatizar tareas burocráticas como la creación de carátulas y referencias bibliográficas.

Construida con **Flutter** y siguiendo los principios de **Clean Architecture**, StudyFlow es un proyecto *Offline-First* que garantiza rendimiento y persistencia local segura.

---

## ✨ Características Principales

### 📊 1. Gestión Académica (Core)
- **Dashboard en Tiempo Real:** Visualización inmediata del Promedio Ponderado Semestral, créditos matriculados y cursos aprobados.
- **Sistema de Notas Flexible:** Registro de evaluaciones con pesos porcentuales personalizados (ej: Parcial 30%, Final 40%).
- **Cálculo "Salva Semestres":** Lógica predictiva que te indica cuánto necesitas sacar en tu examen final para aprobar el curso.
- **Historial de Ciclos:** Organización por semestres (2025-I, 2025-II, etc.).

### 🛠️ 2. Módulo de Herramientas (AutoTemplate)
- **📄 Generador de Carátulas PDF:**
  - Crea portadas oficiales en segundos seleccionando tu universidad (UNMSM, UNI, etc.).
  - Exportación directa a PDF listo para imprimir o adjuntar.
  - Soporte para logos dinámicos y listas de integrantes.
- **🤖 Generador APA 7 Pro:**
  - Web Scraping de metadatos: Pega un link y la app extrae el Título, Sitio Web y Año automáticamente.
  - Formateo automático de referencias bibliográficas listo para copiar al portapapeles.

---

## 📸 Galería

| Dashboard Global | Generador PDF (UNMSM) |
|:---:|:---:|
| <img src="screenshots/dashboard.png" width="400" alt="Dashboard Principal"> | <img src="screenshots/pdf_generator.png" width="400" alt="Generador PDF"> |
| *Resumen de notas y promedios en tiempo real* | *Exportación de carátulas formales* |

| Generador APA 7 | Gestión de Notas |
|:---:|:---:|
| <img src="screenshots/apa_generator.png" width="400" alt="Generador APA"> | <img src="screenshots/grades.png" width="400" alt="Gestión de Notas"> |
| *Extracción automática de metadatos web* | *Cálculo de promedios ponderados* |

---

## 🏗️ Arquitectura y Tecnologías

El proyecto sigue una estructura basada en **Clean Architecture**, separando las capas para asegurar escalabilidad y testabilidad:

- **Presentation:** Widgets, Screens, Providers.
- **Domain:** Entities, Repositories (Interfaces), UseCases.
- **Data:** Models (Hive Adapters), Data Sources, Repository Implementations.

### Stack Tecnológico:
* **Framework:** Flutter (Dart).
* **Base de Datos Local:** [Hive](https://pub.dev/packages/hive) (NoSQL, rápida y ligera).
* **Generación PDF:** `pdf` & `printing`.
* **Web Scraping:** `metadata_fetch` (OpenGraph parser).
* **Formularios:** `flutter_form_builder`.
* **Gestión de Estado:** `ValueListenableBuilder` (Nativo).

---

## 🚀 Instalación y Desarrollo (Para Devs)

Si deseas contribuir o modificar el código fuente:

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/EJK-S/Aplicacion_StudyFlow.git](https://github.com/EJK-S/Aplicacion_StudyFlow.git)
    cd StudyFlow
    ```

2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Generar adaptadores de Hive (si es necesario):**
    ```bash
    dart run build_runner build
    ```

4.  **Ejecutar la app:**
    ```bash
    flutter run
    ```

---

## 🗺️ Hoja de Ruta (Roadmap)

- [x] **MVP Semanas 1-3:** Configuración, Base de Datos Local, Lógica de Promedios.
- [x] **Módulo Herramientas:** Generadores de PDF y Citas APA.
- [x] **Dashboard:** Tarjetas de resumen con gradientes y métricas.
- [ ] **v2.0:** Sincronización en la Nube (Firebase/Supabase).
- [ ] **v2.0:** Notificaciones de tareas y exámenes.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

---

<div align="center">
  <sub>Desarrollado con ❤️ por <a href="https://github.com/EJK-S">Jean Carlo</a></sub>
</div>
