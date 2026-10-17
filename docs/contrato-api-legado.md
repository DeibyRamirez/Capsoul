# API Legado (contrato VPS)

Base: `{API_BASE}/v1`. Autenticación: `Authorization: Bearer <jwt>`.

Implementación actual: **Supabase** (PostgREST + RPC). `RepositorioLegadoHttp` debe devolver los mismos DTOs.

| Método | Ruta | Supabase equivalente |
|--------|------|----------------------|
| GET | `/legado/resumen` | `rpc legado_resumen` |
| GET | `/legado/por-beneficiario` | `rpc legado_agrupado_beneficiario` |
| GET | `/herencias/{id}` | `rpc herencia_detalle` |
| POST | `/herencias` | `insert herencias` |
| PATCH | `/herencias/{id}` | `update herencias` (RLS) |
| POST | `/herencias/{id}/capsulas` | `rpc vincular_capsula_herencia` |
| PUT | `/legado/instrucciones` | `rpc guardar_instrucciones_legado` |
| PUT | `/legado/persona-confianza` | `rpc establecer_persona_confianza_legado` |
| DELETE | `/legado/persona-confianza` | `rpc quitar_persona_confianza_legado` |
| POST | `/herencias/{id}/confirmar` | `rpc confirmar_herencia` |
| POST | `/herencias/{id}/solicitud-legal` | `rpc solicitar_respaldo_legal_herencia` |

Ver metadatos JSON en [`contrato-legado.json`](contrato-legado.json).
