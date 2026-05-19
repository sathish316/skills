#!/usr/bin/env python3
"""
CodeWiki HTML Viewer Generator (Eleventy-based)

Converts codewiki/ markdown files into a beautiful static HTML site with:
- Mermaid diagram rendering
- Code syntax highlighting (Prism.js)
- Sidebar navigation
- Full-text search (Algolia-style interactive)
- Tailwind CSS styling with dark/light mode
- RovoDev Wiki branding

Architecture:
    rovocodewiki/viewer/       — Reusable templates (layouts, includes, config)
    codewiki/                  — Project-specific markdown files (source of truth)
    codewiki/_build/           — Temporary Eleventy build directory (auto-cleaned)
    codewiki/_site/            — Generated HTML output

Usage:
    python rovocodewiki/viewer/generate.py [--codewiki-dir PATH] [--output-dir PATH] [--serve]
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


# ── Page metadata extraction ──

def extract_title(md_content: str) -> str:
    """Extract the first H1 heading from markdown content."""
    match = re.search(r'^#\s+(.+)$', md_content, re.MULTILINE)
    return match.group(1).strip() if match else "Untitled"


def smart_title_case(text: str) -> str:
    """Title-case text while preserving known acronyms (API, MCP, etc.)."""
    acronyms = {'api', 'mcp', 'uct', 'ers', 'ors', 'tcs', 'twg', 'jsr', 'pir',
                'sdk', 'http', 'url', 'json', 'yaml', 'html', 'css', 'sql',
                'aws', 'gcp', 'ci', 'cd', 'ui', 'ux', 'sla', 'slo', 'io',
                'agg', 'jwt', 'asap', 'jira', 'aiops'}
    words = text.split()
    result = []
    for word in words:
        if word.lower() in acronyms:
            result.append(word.upper())
        elif word.isupper() and len(word) > 1:
            result.append(word)
        else:
            result.append(word.capitalize())
    return ' '.join(result)


def make_short_title(title: str, section: str = None) -> str:
    """Create a shorter, capitalized title for the sidebar."""
    if section == 'deep-dive':
        if title.startswith('Deep Dive:'):
            short = title[len('Deep Dive:'):].strip()
            if short:
                return smart_title_case(short)
    else:
        if ':' in title:
            short = title.split(':')[0].strip()
            if short:
                return smart_title_case(short)
    return smart_title_case(title)


def slug_to_title(slug: str) -> str:
    """Convert a filename slug like 'api-layer' to 'API Layer'."""
    cleaned = re.sub(r'^\d+-', '', slug)
    return smart_title_case(cleaned.replace('-', ' ').replace('_', ' '))


def compute_order(filename: str) -> int:
    """Extract numeric order from filename like '1-project-overview.md' -> 1."""
    match = re.match(r'^(\d+)', Path(filename).name)
    return int(match.group(1)) if match else 999


# ── Markdown file discovery ──

def discover_markdown_files(codewiki_dir: Path) -> list:
    """Discover all markdown files in the codewiki directory."""
    files = []

    # Top-level files (sorted by name)
    for f in sorted(codewiki_dir.glob('*.md')):
        files.append(('top', f))

    # Deep-dive files
    deep_dive_dir = codewiki_dir / '6-deep-dive'
    if deep_dive_dir.exists():
        for f in sorted(deep_dive_dir.glob('*.md')):
            files.append(('deep-dive', f))

    return files


# ── Frontmatter injection ──

def add_frontmatter(md_content: str, title: str, short_title: str,
                    order: int, section: str = None, permalink: str = None) -> str:
    """Prepend YAML frontmatter to markdown content."""
    fm_lines = [
        '---',
        f'title: "{title}"',
        f'shortTitle: "{short_title}"',
        f'order: {order}',
        'layout: base.njk',
        'tags: wiki',
    ]
    if section:
        fm_lines.append(f'section: {section}')
    if permalink:
        fm_lines.append(f'permalink: "{permalink}"')
    fm_lines.append('---')
    fm_lines.append('')

    return '\n'.join(fm_lines) + md_content


# ── Build directory setup ──

def prepare_build_dir(codewiki_dir: Path, viewer_dir: Path) -> tuple:
    """Create a temporary build directory with templates and enriched markdown files.

    Returns (build_dir, page_count).
    """
    build_dir = codewiki_dir / '_build'

    # Clean previous build
    if build_dir.exists():
        shutil.rmtree(build_dir)

    # Create build structure:
    #   _build/
    #     _includes/     ← copied from viewer templates
    #     _layouts/      ← copied from viewer templates
    #     wiki/          ← enriched markdown files
    #     index.md       ← redirect page
    template_src = viewer_dir / 'src'
    shutil.copytree(template_src / '_includes', build_dir / '_includes')
    shutil.copytree(template_src / '_layouts', build_dir / '_layouts')

    # Copy enriched markdown files
    wiki_dir = build_dir / 'wiki'
    wiki_dir.mkdir(parents=True, exist_ok=True)
    deep_dive_out = wiki_dir / 'deep-dive'
    deep_dive_out.mkdir(parents=True, exist_ok=True)

    md_files = discover_markdown_files(codewiki_dir)
    if not md_files:
        print(f"❌ No markdown files found in {codewiki_dir}")
        sys.exit(1)

    page_count = 0
    first_slug = None

    for section, md_file in md_files:
        raw = md_file.read_text(encoding='utf-8')
        title = extract_title(raw)
        short_title = make_short_title(title, section=section)
        order = compute_order(md_file.name)
        slug = md_file.stem

        if section == 'deep-dive':
            permalink = f'/deep-dive/{slug}/'
            out_file = deep_dive_out / md_file.name
            enriched = add_frontmatter(raw, title, short_title,
                                       order=100 + order,
                                       section='deep-dive',
                                       permalink=permalink)
        else:
            permalink = f'/{slug}/'
            out_file = wiki_dir / md_file.name
            enriched = add_frontmatter(raw, title, short_title,
                                       order=order,
                                       permalink=permalink)

        if first_slug is None:
            first_slug = slug

        out_file.write_text(enriched, encoding='utf-8')
        page_count += 1

    # Create index page that redirects to first page
    index_content = f"""---
title: "RovoDev Wiki"
permalink: /
layout: base.njk
---
<meta http-equiv="refresh" content="0; url=/{first_slug}/">
<p>Redirecting to <a href="/{first_slug}/">documentation</a>...</p>
"""
    (build_dir / 'index.md').write_text(index_content, encoding='utf-8')

    print(f"   Prepared {page_count} markdown pages")
    return build_dir, page_count


# ── Eleventy runner ──

def ensure_node_modules(viewer_dir: Path):
    """Install npm dependencies if not already present."""
    node_modules = viewer_dir / 'node_modules'
    if not node_modules.exists():
        print("   Installing dependencies...")
        subprocess.run(['npm', 'install'], cwd=viewer_dir, check=True,
                       capture_output=True, text=True)


def run_eleventy(viewer_dir: Path, build_dir: Path, output_dir: Path,
                 serve: bool = False, port: int = 8088):
    """Run Eleventy to build or serve the site.

    Eleventy is run with:
      --input=<build_dir>     (the temp build dir with templates + markdown)
      --config=<viewer_dir>/eleventy.config.js  (reusable config)
      ELEVENTY_OUTPUT=<output_dir>  (via env var, read by config)
    """
    ensure_node_modules(viewer_dir)

    config_path = viewer_dir / 'eleventy.config.js'
    env = os.environ.copy()
    env['ELEVENTY_OUTPUT'] = str(output_dir)

    # npx resolves from viewer_dir where node_modules lives
    base_cmd = [
        'npx', 'eleventy',
        f'--input={build_dir}',
        f'--config={config_path}',
    ]

    if serve:
        print(f"\n🌐 Serving CodeWiki at http://localhost:{port}")
        print("   Press Ctrl+C to stop\n")
        subprocess.run(base_cmd + [f'--port={port}', '--serve'],
                       cwd=viewer_dir, env=env)
    else:
        print("   Building site with Eleventy...")
        result = subprocess.run(base_cmd,
                                cwd=viewer_dir, capture_output=True, text=True,
                                env=env)
        if result.returncode != 0:
            print(f"❌ Eleventy build failed:\n{result.stderr}")
            sys.exit(1)
        print(f"   {result.stdout.strip().split(chr(10))[-1]}")


# ── Main orchestration ──

def generate_site(codewiki_dir: Path, output_dir: Path, serve: bool = False, port: int = 8088):
    """Generate the complete HTML site."""
    viewer_dir = Path(__file__).parent.resolve()

    print("📚 RovoDev Wiki Generator")
    print(f"   Source:  {codewiki_dir}")
    print(f"   Output:  {output_dir}")

    build_dir, page_count = prepare_build_dir(codewiki_dir, viewer_dir)

    try:
        run_eleventy(viewer_dir, build_dir, output_dir, serve=serve, port=port)
    finally:
        # Clean up temp build directory (unless serving — user may Ctrl+C)
        if not serve and build_dir.exists():
            shutil.rmtree(build_dir)

    if not serve:
        print(f"\n✅ CodeWiki site generated!")
        print(f"   Output: {output_dir / 'index.html'}")
        print(f"   Pages:  {page_count}")
        print(f"\n   Open in browser:")
        print(f"   open {output_dir / 'index.html'}")


# ── CLI ──

def main():
    parser = argparse.ArgumentParser(description='Generate RovoDev Wiki HTML viewer')
    parser.add_argument('--codewiki-dir', type=str, default='codewiki',
                        help='Path to codewiki markdown directory (default: codewiki)')
    parser.add_argument('--output-dir', type=str, default='codewiki/_site',
                        help='Path to output directory (default: codewiki/_site)')
    parser.add_argument('--serve', action='store_true',
                        help='Start a local dev server after generating')
    parser.add_argument('--port', type=int, default=8088,
                        help='Port for local server (default: 8088)')
    args = parser.parse_args()

    codewiki_dir = Path(args.codewiki_dir).resolve()
    output_dir = Path(args.output_dir).resolve()

    if not codewiki_dir.exists():
        print(f"❌ CodeWiki directory not found: {codewiki_dir}")
        sys.exit(1)

    generate_site(codewiki_dir, output_dir, serve=args.serve, port=args.port)


if __name__ == '__main__':
    main()
