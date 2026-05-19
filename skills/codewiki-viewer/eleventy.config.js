const markdownIt = require("markdown-it");
const markdownItAnchor = require("markdown-it-anchor");

module.exports = function (eleventyConfig) {
  // ── Markdown configuration ──
  const md = markdownIt({
    html: true,
    linkify: true,
    typographer: true,
  }).use(markdownItAnchor, {
    permalink: markdownItAnchor.permalink.headerLink(),
    slugify: (s) =>
      s
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, ""),
  });

  // Custom fence renderer for mermaid blocks
  const defaultFence = md.renderer.rules.fence;
  md.renderer.rules.fence = function (tokens, idx, options, env, self) {
    const token = tokens[idx];
    if (token.info.trim() === "mermaid") {
      const escaped = md.utils.escapeHtml(token.content);
      return `<div class="mermaid-wrapper my-6 relative group">
        <button onclick="openMermaidFullscreen(this)" class="mermaid-expand-btn absolute top-2 right-2 z-10 p-1.5 rounded-lg bg-white/80 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-600 text-gray-500 hover:text-indigo-600 hover:bg-white dark:hover:bg-gray-700 opacity-0 group-hover:opacity-100 transition-all shadow-sm" title="View fullscreen">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5v-4m0 4h-4m4 0l-5-5"/></svg>
        </button>
        <pre class="mermaid">${escaped}</pre>
      </div>\n`;
    }
    // Default fence with syntax highlighting classes
    const lang = token.info.trim();
    const code = md.utils.escapeHtml(token.content);
    const langLabel = lang
      ? `<span class="code-lang-label">${md.utils.escapeHtml(lang)}</span>`
      : "";
    return `<div class="code-block-wrapper">${langLabel}<pre class="code-block"><code class="language-${lang}">${code}</code></pre></div>\n`;
  };

  eleventyConfig.setLibrary("md", md);

  // ── Pass-through copy ──
  eleventyConfig.addPassthroughCopy({ "src/assets": "assets" });

  // ── Collections ──
  // All wiki pages sorted by filename
  eleventyConfig.addCollection("wikiPages", function (collectionApi) {
    return collectionApi
      .getFilteredByTag("wiki")
      .sort((a, b) => {
        const orderA = a.data.order || 999;
        const orderB = b.data.order || 999;
        return orderA - orderB;
      });
  });

  // Top-level pages
  eleventyConfig.addCollection("topPages", function (collectionApi) {
    return collectionApi
      .getFilteredByTag("wiki")
      .filter((p) => !p.data.section)
      .sort((a, b) => (a.data.order || 999) - (b.data.order || 999));
  });

  // Deep dive pages
  eleventyConfig.addCollection("deepDivePages", function (collectionApi) {
    return collectionApi
      .getFilteredByTag("wiki")
      .filter((p) => p.data.section === "deep-dive")
      .sort((a, b) => (a.data.order || 999) - (b.data.order || 999));
  });

  // ── Filters ──
  eleventyConfig.addFilter("extractHeadings", function (content) {
    if (!content) return [];
    const headingRegex = /<h([2-4])\s+id="([^"]*)"[^>]*>(.*?)<\/h\1>/gi;
    const headings = [];
    let match;
    while ((match = headingRegex.exec(content)) !== null) {
      // Strip HTML tags from heading text
      const text = match[3].replace(/<[^>]+>/g, "").trim();
      headings.push({ level: parseInt(match[1]), id: match[2], text });
    }
    return headings;
  });

  eleventyConfig.addFilter("jsonStringify", function (value) {
    return JSON.stringify(value);
  });

  eleventyConfig.addFilter("striptags", function (value) {
    if (!value) return "";
    // Remove HTML tags and collapse whitespace
    return value.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  });

  // ── Config ──
  // Note: input dir is passed via --input flag from generate.py
  // Output dir is set via ELEVENTY_OUTPUT env var
  return {
    dir: {
      output: process.env.ELEVENTY_OUTPUT || "_site",
      includes: "_includes",
      layouts: "_layouts",
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
    templateFormats: ["md", "njk", "html"],
  };
};
