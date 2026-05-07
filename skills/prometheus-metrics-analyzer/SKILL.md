---
name: prometheus-metrics-analyzer
description: Analyze metrics to debug alerts or incidents
---

# Metrics Analyzer Skill

## Prometheus MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__prometheus__prometheus_list_metrics` | List all available metrics |
| `mcp__prometheus__prometheus_metric_metadata` | Get metadata (type, description) for a metric |
| `mcp__prometheus__prometheus_list_labels` | List label names for filtering |
| `mcp__prometheus__prometheus_label_values` | Get values for a label (e.g. service names) |
| `mcp__prometheus__prometheus_query` | Run an instant PromQL query |
| `mcp__prometheus__prometheus_query_range` | Run a range query (use for last 30 mins) |

## Debugging Workflow

1. **Find relevant metrics** — Use `prometheus_list_metrics` to browse available metrics, then `prometheus_metric_metadata` to confirm type and description. Select up to 5 metrics most relevant to the issue. You don't have to always select 5 metrics if fewer metrics are enough to debug the issue

2. **Query each metric for the last 30 mins** — Use `prometheus_query_range` with `start` = now-30m, `end` = now, `step` = 60s.

3. **Find error patterns** — Look for spikes, drops, elevated rates, or flatlines. For counters, query the rate. For histograms, query the p99 latency or error ratio.

4. **Explain the issue** — Summarize what each metric shows, correlate patterns across metrics, and state the likely root cause.

## Rules

- Query at most 5 metrics per investigation.
- Always use a 30-minute range unless the user specifies otherwise.
- Prefer metrics with `error`, `failure`, `timeout`, `latency`, or `saturati` in the name when debugging incidents.
- Use `prometheus_label_values` to scope queries to a specific service or namespace if known.
