# CI/CD Updates Summary

## TruffleHog action
- Switched from `trufflesecurity/trufflehog@v3` to `trufflesecurity/trufflehog-actions@v0.0.8`.
- Adjusted inputs to use `path: .` with `extra_args: --only-verified` for filesystem scanning.
- Applied in both CI and CI/CD workflows where applicable.

## GCP Service Account secret
- Clarified usage of `GCP_SA_KEY` in workflows (JSON key stored in GitHub repository secrets).
- Commented in CI/CD workflow how to add the secret: Settings → Secrets → Actions.

## Cloud Run resource tuning
- Backend:
  - `--min-instances=1`, `--max-instances=10`, `--memory=1Gi` to ensure availability and scale.
- Frontend:
  - `--min-instances=0`, `--max-instances=5`, `--memory=512Mi` to optimize cost.
  - Added `NEXT_PUBLIC_WS_URL` to support WebSocket endpoints.
- FinGPT (ML service):
  - Added build/push and deploy steps.
  - `--cpu=2`, `--memory=8Gi`, `--min-instances=0`, `--max-instances=2`.

## Artifact Registry
- Added instructions in README and deployment docs for authenticating Docker via:
  - `gcloud auth configure-docker us-central1-docker.pkg.dev`, or
  - `gcloud auth print-access-token | docker login ...`.

