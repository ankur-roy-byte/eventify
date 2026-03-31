# Security Rollout

This repository includes a two-stage security plan.

## Prerequisites

- Copy `infra/compose/.env.example` to `infra/compose/.env.local`.
- Replace every `CHANGE_ME_*` value with strong local credentials.
- Never commit `infra/compose/.env.local`, certificates, or keystores.

## Stage A: TLS-only

- Encrypt broker/client traffic with TLS.
- Keep authentication disabled for local developer ergonomics.
- Useful for validating cert management and encrypted links.

Run:
- `make up-tls`

## Stage B: SASL/SCRAM + TLS + ACL

- Enable SASL_SSL listeners.
- Configure SCRAM credentials for service principals.
- Enable ACL authorization using:
  - `authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer`
- Define `super.users` minimally and rotate admin credentials.

Run:
- `make up-sasl`
- `make scram-users`
- `make acls`

See `server.properties.stage-b.example` and `../scripts/create-acls.sh`.
