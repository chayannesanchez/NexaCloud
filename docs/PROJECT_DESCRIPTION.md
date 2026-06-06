# Descripción del proyecto

Este documento resume el enunciado base del proyecto **Despliegue de una Aplicación Web Utilizando CI/CD con AWS Lambda y API Gateway**.

El archivo original del enunciado se encuentra disponible en:

- [`docs/assets/project-description.pdf`](assets/project-description.pdf)

## Empresa

**NexaCloud** es una empresa emergente de tecnología que ofrece servicios de atención al cliente a través de una plataforma web.

## Contexto

La empresa se encuentra en crecimiento y busca optimizar los costos de infraestructura mediante una arquitectura **serverless** para el backend. También requiere automatizar los despliegues para mejorar la eficiencia del equipo de desarrollo.

## Necesidad

La solución debe permitir que los usuarios ingresen solicitudes de soporte desde un formulario web. Estas solicitudes deben almacenarse en una base de datos y el equipo de soporte debe poder consultarlas fácilmente.

Adicionalmente, el proyecto debe reducir el tiempo entre desarrollo y despliegue por medio de un proceso de **integración y entrega continua CI/CD**.

## Objetivo general

Desarrollar y desplegar una aplicación web que permita enviar solicitudes de soporte y utilizar un pipeline CI/CD para desplegar automáticamente nuevas características en AWS Lambda, gestionadas por API Gateway.

Los datos enviados por los usuarios deben almacenarse en DynamoDB y el equipo de soporte debe contar con acceso para visualizar las solicitudes.

## Alcance funcional

- Formulario web para crear solicitudes de soporte.
- API para recibir y consultar solicitudes.
- Persistencia de datos en DynamoDB.
- Panel o acceso para que soporte pueda revisar las solicitudes.
- Autenticación básica para proteger la visualización de solicitudes.
- Monitoreo de funciones Lambda con CloudWatch.
- Pipeline CI/CD para automatizar despliegues desde el repositorio.

## Requisitos técnicos

### Backend

- Crear funciones AWS Lambda para manejar solicitudes HTTP.
- Configurar API Gateway para exponer los endpoints.
- Crear tabla DynamoDB para almacenar solicitudes de soporte.
- Guardar información como nombre, correo electrónico, descripción del problema y timestamp.

### Frontend

- Crear una página web con HTML, CSS y JavaScript.
- Incluir formulario para capturar nombre, correo y mensaje.
- Integrar el frontend con la API expuesta por API Gateway.

### CI/CD

- Configurar GitHub Actions o AWS CodePipeline.
- Automatizar despliegues al realizar commits en la rama principal.
- Ejecutar pruebas si aplica.
- Configurar notificaciones ante fallos del pipeline.

## Criterios de éxito

- La aplicación debe ser funcional desde un navegador web.
- Las solicitudes deben almacenarse correctamente en DynamoDB.
- Las solicitudes deben ser recuperables desde la API.
- El pipeline CI/CD debe desplegar automáticamente los cambios.
- La arquitectura debe ser escalable y optimizada en costos.
- Solo usuarios autenticados deben poder ver las solicitudes de soporte.
- CloudWatch debe monitorear invocaciones de Lambda y generar alarmas en caso de fallas.

## Entrega esperada

- Repositorio GitHub con frontend, backend y pipeline CI/CD.
- Documentación clara en `README.md`.
- Presentación del proyecto.
- Diagrama visual de arquitectura.
