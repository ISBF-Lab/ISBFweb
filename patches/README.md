# Fixed external plugin integrations

The production `isbf-learning` and `isbf-official` plugins are installed as symlinks to immutable directories under `/shared`. Their source directories are deliberately outside the core Git checkout.

The moderator permission patches apply to these production baselines:

| Plugin | Baseline release directory |
| --- | --- |
| `isbf-learning` | `/shared/isbf-learning-releases/621f938a6676533fce0f7e725b77c485cef965d1/isbf-learning` |
| `isbf-official` | `/shared/isbf-official-releases/3fb65735e202cac77c635f14cadad12ac473f7a4/isbf-official` |

The exact release references and hashes for every file are captured by `deploy-work/admin-permissions-20261011/inventory.py` before building. The build must reject a changed baseline, apply these patches to complete copies, and retain every unrelated source file and release marker. The deployment publishes new immutable directories and replaces only the two plugin symlinks. Keep the original directories available for rollback.

For a matching development installation, run `git apply patches/isbf-learning/moderator-permissions.patch patches/isbf-official/moderator-permissions.patch` from the core checkout. Do not apply again if the installation already uses the permission release. See [the permission guide](../docs/admin-permissions.md) for capability names and validation.
