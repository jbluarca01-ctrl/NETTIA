---
id: cloud-modelos-servicio-despliegue
tema: cloud
subtema: conceptos
titulo: "Nube: 5 características, modelos IaaS/PaaS/SaaS y tipos de despliegue"
nivel: basico
plataforma: generico
version: NIST SP 800-145
protocolo: cloud
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: cloud, nube, iaas, paas, saas, nube publica, nube privada, nube hibrida, nube comunitaria, elasticidad, autoservicio, nist 800-145
fuente: NIST SP 800-145 - The NIST Definition of Cloud Computing | §2 Essential Characteristics, Service Models, Deployment Models | https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-145.pdf
fuente: Cisco - What is Cloud Computing? | Cloud service and deployment models | https://www.cisco.com/c/en_uk/solutions/cloud/what-is-cloud-computing.html
---
La definición de referencia (NIST SP 800-145) dice que un servicio es "nube" si cumple **5 características esenciales**:

| Característica | Qué significa |
|---|---|
| Autoservicio bajo demanda | El cliente se asigna recursos solo, sin hablar con nadie del proveedor. |
| Acceso amplio por red | Se usa por la red con mecanismos estándar, desde distintos dispositivos. |
| Pool de recursos | El proveedor comparte su hardware entre muchos clientes (multi-tenant). |
| Elasticidad rápida | Los recursos crecen o se reducen rápido según la demanda. |
| Servicio medido | El uso se mide (y normalmente se cobra) automáticamente. |

**Modelos de servicio** (la diferencia es **qué controla el cliente**):
- **IaaS** (infraestructura): el cliente maneja sistema operativo, middleware, aplicaciones y datos; el proveedor, los servidores, el almacenamiento, la red y la virtualización. Ej.: alquilar máquinas virtuales.
- **PaaS** (plataforma): el cliente solo despliega **sus aplicaciones**; el proveedor maneja también el sistema operativo y el middleware.
- **SaaS** (software): el cliente solo **usa la aplicación** (y ajusta su configuración de usuario); todo lo demás es del proveedor. Ej.: correo web.

**Modelos de despliegue:**
- **Privada:** para una sola organización.
- **Comunitaria:** compartida por varias organizaciones con necesidades comunes.
- **Pública:** abierta al público general, operada por un proveedor.
- **Híbrida:** combinación de dos o más de las anteriores, conectadas pero que siguen siendo nubes distintas.
