---
name: raindrop-bookmarks
description: Manage Raindrop.io bookmarks, collections, tags, highlights, imports, exports, and bookmark cleanup via the Raindrop REST API. Use when the user mentions Raindrop, raindrop.io, bookmarks, saved links, collections, tags, web highlights, reading lists, URL organization, or asks to search, save, update, move, bulk edit, import, export, or audit bookmarks.
---

# Raindrop Bookmarks

Manage the user's Raindrop.io library through the REST API.

This skill is copied and adapted from `gmickel/raindrop-skill` for the local `raindrop-bookmarks` workflow.

## Prerequisites

Require `RAINDROP_TOKEN` in the shell environment before making API calls.

If it is missing, tell the user to:

1. Create an app at `https://app.raindrop.io/settings/integrations`
2. Generate a test token
3. Add `export RAINDROP_TOKEN="..."` to `~/.zshrc.local` or another local shell env file

Never print the token. Do not commit it to the repository.

## Helper Script

Use the bundled helper for routine API calls:

```bash
{baseDir}/scripts/raindrop.sh GET /collections
{baseDir}/scripts/raindrop.sh POST /raindrop '{"link":"https://example.com","pleaseParse":{}}'
{baseDir}/scripts/raindrop.sh PUT /raindrop/123 '{"tags":["new-tag"]}'
{baseDir}/scripts/raindrop.sh DELETE /raindrop/123
```

When invoking from a shell manually, replace `{baseDir}` with the skill directory path.

## Safety

Ask the user for confirmation before destructive or broad write operations:

- Deleting raindrops, collections, tags, backups, or collaborator access
- Moving items to trash or permanently removing items already in trash
- Bulk updating, bulk moving, merging, or cleaning collections/tags
- Running imports or exports that write files into the workspace

Read-only operations and single explicit creates/updates do not need confirmation unless the user's intent is ambiguous.

## Quick Reference

Base URL:

```text
https://api.raindrop.io/rest/v1
```

Authentication header:

```text
Authorization: Bearer $RAINDROP_TOKEN
```

Special collection IDs:

- `0`: all bookmarks
- `-1`: unsorted
- `-99`: trash

## Common Operations

### Verify Access

```bash
{baseDir}/scripts/raindrop.sh GET /user
```

### List Collections

```bash
{baseDir}/scripts/raindrop.sh GET /collections
{baseDir}/scripts/raindrop.sh GET /collections/childrens
```

### Save Bookmark

Use `pleaseParse: {}` when the user wants Raindrop to fetch title, excerpt, cover, type, and metadata.

```bash
{baseDir}/scripts/raindrop.sh POST /raindrop '{
  "link": "https://example.com",
  "collection": {"$id": 12345},
  "tags": ["tag1", "tag2"],
  "pleaseParse": {}
}'
```

### Search Bookmarks

```bash
{baseDir}/scripts/raindrop.sh GET '/raindrops/0?search=keyword&sort=-created'
```

Useful search operators:

- `#tag`: tag search
- `type:article`: type search, including `link`, `article`, `image`, `video`, `document`, `audio`
- `domain:example.com`: domain search
- `created:>2024-01-01`: date search
- `important:true`: favorites only

### Update Bookmark

```bash
{baseDir}/scripts/raindrop.sh PUT /raindrop/123 '{
  "tags": ["research", "reading"],
  "collection": {"$id": 456},
  "important": true
}'
```

### Create Collection

```bash
{baseDir}/scripts/raindrop.sh POST /collection '{
  "title": "My Collection",
  "public": false
}'
```

### Add Highlight

```bash
{baseDir}/scripts/raindrop.sh PUT /raindrop/123 '{
  "highlights": [{"text": "highlighted text", "color": "yellow", "note": "my note"}]
}'
```

Allowed highlight colors: `blue`, `brown`, `cyan`, `gray`, `green`, `indigo`, `orange`, `pink`, `purple`, `red`, `teal`, `yellow`.

### Bulk Tag Bookmarks

Confirm with the user before running.

```bash
{baseDir}/scripts/raindrop.sh PUT /raindrops/0 '{
  "ids": [1, 2, 3],
  "tags": ["new-tag"]
}'
```

### Export Collection

Confirm the destination filename before writing export files.

```bash
curl -s "https://api.raindrop.io/rest/v1/raindrops/{collectionId}/export.csv" \
  -H "Authorization: Bearer $RAINDROP_TOKEN" > bookmarks.csv
```

Supported formats: `csv`, `html`, `zip`.

## Detailed Reference

Read `references/API-REFERENCE.md` when the user asks for endpoint details, less common operations, imports/exports, backups, sharing, filters, OAuth, or fields on API objects.

## Rate Limits

Raindrop allows 120 requests per minute. For larger jobs, batch where possible and watch response headers:

- `X-RateLimit-Limit`
- `RateLimit-Remaining`
- `X-RateLimit-Reset`
