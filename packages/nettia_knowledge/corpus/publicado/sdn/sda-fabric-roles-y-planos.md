---
id: sda-fabric-roles-y-planos
tema: sdn
subtema: sd-access
titulo: "Cisco SD-Access: underlay/overlay, LISP, VXLAN, SGT y roles del fabric"
nivel: avanzado
plataforma: generico
version: Catalyst Center (antes DNA Center)
protocolo: sd-access
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: sd-access, sda, dna center, catalyst center, fabric, underlay, overlay, lisp, vxlan, trustsec, sgt, control plane node, edge node, border node
fuente: Cisco Design Zone - Software-Defined Access Design Guide | SD-Access Architecture, Fabric Roles | https://www.cisco.com/c/en/us/td/docs/solutions/CVD/Campus/cisco-sda-design-guide.html
fuente: Cisco Catalyst Center - SD-Access Deployment Using Cisco Catalyst Center (Validated Profile) | Solution Overview | https://www.cisco.com/c/en/us/td/docs/cloud-systems-management/network-automation-and-management/catalyst-center/cisco-validated-solution-profiles/validated-profile-sda-deployment.html
---
SD-Access es la aplicación de SDN de Cisco a la red de campus. Se arma en dos capas:

- **Underlay:** la red física de switches y routers, toda enrutada en capa 3 (incluidos los switches de acceso), con un protocolo de ruteo como IS-IS u OSPF. Solo se encarga de que haya conectividad IP entre los equipos del fabric.
- **Overlay:** redes virtuales que viajan **encapsuladas** sobre el underlay. Pueden correr varias redes virtuales aisladas sobre la misma red física, y una subred puede estirarse entre equipos que están físicamente separados.

**Un protocolo por plano:**

| Plano | Tecnología | Para qué |
|---|---|---|
| Control | **LISP** | Separa la **identidad** del equipo (su IP, EID) de su **ubicación** en la red (RLOC). Un equipo puede moverse sin cambiar de IP. |
| Datos | **VXLAN** | Encapsula la trama Ethernet original dentro de IP (MAC-en-IP) para llevarla por el underlay. |
| Políticas | **Cisco TrustSec (SGT)** | Aplica permisos por **grupo** (etiquetas SGT) en vez de por dirección IP. |

**Roles de los equipos del fabric:**
- **Control plane node:** el "directorio" (map-server/map-resolver). Sabe en qué punto del fabric está cada equipo final.
- **Edge node:** el switch de acceso. Conecta a los usuarios, registra sus equipos en el control plane node, hace de gateway y encapsula y desencapsula VXLAN.
- **Border node:** la salida del fabric hacia redes externas (otras sedes, datacenter, Internet).

**Catalyst Center** (antes DNA Center) es el controlador/gestor central: **automatiza** el despliegue y la configuración de los equipos, **administra las políticas** por grupo (junto con Cisco ISE) y da **assurance** (monitoreo y análisis de salud de la red).
