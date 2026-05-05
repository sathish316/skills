---
name: LogAnalyzer
description: Analyze logs to investigate errors and exceptions
---

# Log Analyzer Skill

## Loki MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__loki__loki_label_names` | List available Loki labels for scoping queries. |
| `mcp__loki__loki_label_values` | Get values for a label, such as `job`, `service`, `namespace`, or `container`. |
| `mcp__loki__loki_query` | Run a LogQL query over a time range and return matching log entries. |

## Query Examples

```logql
{job="tribe-web-app"} |= "error"
{job="tribe-web-app"} |= "exception"
{job="tribe-web-app"} |~ "(?i)error|exception|failed|timeout|refused"
{job="tribe-web-app"} | json | level="error"
{job="tribe-web-app"} | json | request_id="<request_id>"
{job="tribe-web-app"} | json | route="/attendees/search" | status >= 400
```

Use `|=` for substring grep, `|~` for regex grep, and `| json` when logs are structured JSON.

## Debugging Workflow

1. **Find log labels** — Use `loki_label_names`, then `loki_label_values` for likely scoping labels such as `job`, `service`, `namespace`, `container`, `app`, or `pod`.

2. **Query recent errors** — Use `loki_query` for the last 30 minutes unless the user specifies another range. Start with broad grep patterns like `error`, `exception`, `failed`, `timeout`, `refused`, and HTTP status strings such as ` 4`, ` 5`, `status=4`, or `status_code`.

3. **Narrow the query** — Add labels and structured filters for the affected service, route, endpoint, request ID, status code, user-visible error, or dependency name.

4. **Correlate log entries** — Group related messages by timestamp, request ID, route, dependency, and error message. Look for the first error in each request flow, not only the final failure response.

5. **Explain the issue** — Summarize the important log lines, the pattern they show, and the likely root cause. Include concrete timestamps, labels, routes, status codes, and request IDs when available.

## Rules

- Query at most 5 distinct LogQL patterns per investigation unless the user asks for a deeper search.
- Always use a 30-minute range unless the user specifies otherwise.
- Prefer scoped label queries over broad log searches once useful labels are known.
- Start broad, then refine with route, request ID, status code, dependency, or exact error message.
- Do not paste large log dumps; quote only the few lines needed and summarize the rest.
