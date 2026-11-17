# Forum assistant backend specs

All fixtures are synthetic. Model responses use
`DiscourseAi::Completions::Llm.with_prepared_responses` or WebMock at the provider
HTTP boundary; no real provider,
production database or development database is used.

Run from the enclosing ISBF-One workspace:

```sh
python3 docs/forum-assistant-20261117/run_specs.py
```

The runner uses disposable offline PostgreSQL and Redis. Its JSON and log reports
are written to `docs/forum-assistant-20261117/results/`.

## Spec audit

| # | Service-authoring requirement | Verdict | Evidence |
|---|---|---|---|
| 1 | Separate contract tests with Shoulda matchers | PASS | `answer_spec.rb`, contract presence validation |
| 2 | Service execution grouped under `.call` | PASS | `answer_spec.rb` |
| 3 | Shared, parameterized result subject declared first | PASS | `.call` subject uses params and dependencies |
| 4 | Fixture, params and dependency setup order | PASS | Shared context provides fab fixtures before value lets |
| 5 | Context for each service branch | PASS | Missing request, authorization, decision failure, cancellation, deny, clarify, source/no-source |
| 6 | Service-specific failure and success matchers | PASS | Contract/model/policy matchers and `run_successfully` |
| 7 | Contract execution test only proves the halt | PASS | One invalid request ID scenario |
| 8 | Happy path verifies success and owned side effects | PASS | Saved answer, source refs, channel publications and quota charge |
| 9 | Branches override values instead of repeating the subject | PASS | `params`, classification and response lets |
| 10 | Actor overrides use fixture declarations | NA | Actor changes are not needed in nested service contexts; HTTP auth cases use distinct fixtures |
| 11 | Specific, observable assertions | PASS | Database state, HTTP status, emitted messages, external prompt bounds |
| 12 | Context descriptions state the condition | PASS | Service contexts use “when …” |
| 13 | Events use tracking helpers | NA | No event-specific assertion is needed; persistence and MessageBus are the public outcomes |
| 14 | MessageBus tracking is a lazy let | PASS | Streaming scenario's `messages` let |
| 15 | Fixtures use fabricators | PASS | Users, model, agent, source posts, guides, categories and account link |
| 16 | Required original posts exist | PASS | Explicit source-post fabricators and real PostCreator provide OP records |
| 17 | Added model callbacks tested through public operations | PASS | PostCreator admission and digest recording in `request_spec.rb` |
| 18 | Complex actions tested independently | PASS | Request/quota, evidence, classifier, job and HTTP suites |
| 19 | Tests follow the service flow | PASS | Contract → request → access → classification → outcome |
| 20 | Specs written in the delegated spec phase | PASS | Dedicated `forum_assistant_specs` agent owns this directory |

## Boundaries checked

- Exact personal and global daily boundaries, Redis minute limit and concurrency,
  per-account independence, local-midnight rollover, deduplication and refunds.
- Scope decisions, invalid model output, no-evidence fallback, bounded source text,
  bounded keyword search fallback, streaming without callable or native tools,
  DeepSeek thinking disabled for classification and answers, provider failures and
  old job rejection.
- Current category permissions, revoked membership, hidden/deleted/unlisted posts,
  private messages, unpublished and withdrawn guides, public course/library metadata.
- Public status, question creation, direct posts, retry, stop/cancel, private
  invitations, sharing, alternate AI calls, admin metadata and cooldown release.

These deterministic tests verify policy enforcement and integration. They do not
measure a real model's semantic classification accuracy or replace provider-backed
evaluation of adversarial questions.
