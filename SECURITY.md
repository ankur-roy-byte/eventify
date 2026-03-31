# Security Policy

## Supported Versions

This repository is a reference architecture and does not publish versioned releases yet.
Security fixes are applied on the default branch.

## Reporting a Vulnerability

Please do not open public issues for security vulnerabilities.

Use one of these channels:
1. GitHub private vulnerability reporting for this repository.
2. If private reporting is unavailable, contact the maintainers directly and include:
   - vulnerability type
   - affected file/path
   - reproduction steps
   - impact assessment
   - suggested remediation

## Security Baselines for Contributors

1. Never commit real credentials, API keys, certificates, or keystores.
2. Use `infra/compose/.env.example` and local-only `infra/compose/.env.local` for secrets.
3. Keep dependency updates current through Dependabot.
4. Ensure CI security workflows (CodeQL and secret scan) pass before merge.
5. Prefer least-privilege accounts for connectors and brokers.
