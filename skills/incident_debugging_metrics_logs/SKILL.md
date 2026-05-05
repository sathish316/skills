---
name: IncidentDebugger
description: Debug and explain production incidents by combining MetricsAnalyzer and LogAnalyzer workflows, correlating Prometheus metrics with Loki logs over the incident window.
---

# Incident Debugging Skill

Use this skill when the user asks to debug, investigate, triage, or explain an incident, outage, alert, error spike, latency spike, degraded service, or suspected production issue.

This is an orchestration skill. It uses both:

- `MetricsAnalyzer` to find the shape, timing, scope, and severity of the incident from Prometheus.
- `LogAnalyzer` to explain the metric pattern with concrete errors, request flows, dependency failures, and timestamps from Loki.

## Workflow

1. **Establish scope**
   - Identify the reported symptom, service, route, dependency, environment, and time range from the user request.
   - If no time range is provided, use the last 30 minutes.
   - If no service is provided, discover likely service labels from metrics and logs before querying broadly.

2. **Analyze metrics first**
   - Follow the `MetricsAnalyzer` skill workflow.
   - Query up to 5 relevant metrics over the incident window.
   - Prefer error rate, request rate, latency, saturation, timeout, retry, and dependency health metrics.
   - Note the first visible change, peak impact, affected labels, and whether the signal recovered.

3. **Analyze logs for explanation**
   - Follow the `LogAnalyzer` skill workflow.
   - Use the metric timeline and labels to scope Loki queries.
   - Query errors, exceptions, failures, timeouts, refused connections, HTTP 4xx/5xx responses, and exact messages suggested by metric labels.
   - Look for the first causal error in a request or dependency flow, not only the final user-facing failure.

4. **Correlate evidence**
   - Align metric changes and log events by timestamp.
   - Connect the affected metric labels to log labels such as service, job, namespace, container, pod, route, status code, request ID, or dependency name.
   - Separate symptoms from likely causes. Treat a spike in 500 responses as a symptom unless logs show why those responses happened.

5. **Explain the incident**
   - State what happened, when it started, what was impacted, and whether it is ongoing.
   - Cite the metric signals and log patterns that support the conclusion.
   - Include a likely root cause only when the evidence supports it; otherwise say what is known and what remains uncertain.
   - Recommend the next debugging or mitigation step if the root cause is not fully proven.

## Output Format

Keep the response short and evidence-led:

- **Status:** ongoing, recovered, or unknown.
- **Impact:** affected service, route, users, dependency, or error class.
- **Timeline:** first detected change, peak, recovery if visible.
- **Evidence:** key metrics and key log patterns with concrete timestamps and labels.
- **Likely cause:** concise explanation, with confidence level.
- **Next step:** one or two concrete actions.

## Rules

- Always use both metrics and logs unless one data source is unavailable; if unavailable, say so.
- Use the same incident window for metrics and logs unless the evidence requires expanding it.
- Default to a 30-minute lookback when the user does not provide a time range.
- Respect the limits from the underlying skills: up to 5 metrics and up to 5 distinct LogQL patterns unless the user asks for deeper investigation.
- Do not paste large raw metric tables or log dumps. Summarize the pattern and quote only the few log lines needed.
- Be explicit about uncertainty. Do not invent a root cause from correlation alone.
