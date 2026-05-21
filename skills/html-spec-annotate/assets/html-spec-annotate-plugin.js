(() => {
  const STORAGE_KEY = `html-spec-feedback:${location.pathname}`;
  const EXPORT_VERSION = 1;
  const UI_ID = "html-spec-feedback-root";
  const PIN_CLASS = "html-spec-feedback-pin";
  const SELECTED_CLASS = "html-spec-feedback-selected";
  const ANCHOR_ATTR = "data-feedback-anchor-id";

  let feedbackMode = false;
  let selectedElement = null;
  let comments = loadComments();

  function init() {
    if (document.getElementById(UI_ID)) {
      return;
    }

    injectStyles();
    ensureAnchorIds();
    buildPanel();
    renderComments();

    document.addEventListener("click", handleDocumentClick, true);
    document.addEventListener("keydown", (event) => {
      if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === "f") {
        event.preventDefault();
        setFeedbackMode(!feedbackMode);
      }
    });
  }

  function injectStyles() {
    const style = document.createElement("style");
    style.textContent = `
      #${UI_ID} {
        position: fixed;
        top: 18px;
        right: 18px;
        z-index: 2147483647;
        width: 360px;
        max-height: calc(100vh - 36px);
        color: #172b4d;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
        font-size: 14px;
      }

      #${UI_ID} * { box-sizing: border-box; }

      .html-spec-feedback-panel {
        border: 1px solid #dfe1e6;
        border-radius: 14px;
        background: #ffffff;
        box-shadow: 0 10px 32px rgba(9, 30, 66, 0.22);
        overflow: hidden;
      }

      .html-spec-feedback-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        padding: 12px 14px;
        background: #0747a6;
        color: #ffffff;
        font-weight: 700;
      }

      .html-spec-feedback-body {
        padding: 12px;
        max-height: calc(100vh - 120px);
        overflow: auto;
      }

      .html-spec-feedback-actions {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 8px;
        margin-bottom: 10px;
      }

      .html-spec-feedback-button,
      .html-spec-feedback-icon-button {
        border: 1px solid #dfe1e6;
        border-radius: 8px;
        background: #f4f5f7;
        color: #172b4d;
        cursor: pointer;
        font: inherit;
        font-weight: 650;
      }

      .html-spec-feedback-button {
        padding: 8px 10px;
      }

      .html-spec-feedback-icon-button {
        width: 28px;
        height: 28px;
        color: #ffffff;
        background: rgba(255,255,255,0.18);
        border-color: rgba(255,255,255,0.35);
      }

      .html-spec-feedback-button:hover,
      .html-spec-feedback-icon-button:hover {
        filter: brightness(0.97);
      }

      .html-spec-feedback-button.primary {
        background: #deebff;
        border-color: #4c9aff;
      }

      .html-spec-feedback-button.active {
        background: #e3fcef;
        border-color: #36b37e;
      }

      .html-spec-feedback-help {
        padding: 9px 10px;
        margin-bottom: 10px;
        border-radius: 8px;
        background: #fffae6;
        border: 1px solid #ffab00;
        color: #5e6c84;
        line-height: 1.35;
      }

      .html-spec-feedback-composer {
        display: none;
        padding: 10px;
        margin-bottom: 10px;
        border: 1px solid #4c9aff;
        border-radius: 10px;
        background: #deebff;
      }

      .html-spec-feedback-composer.visible {
        display: block;
      }

      .html-spec-feedback-anchor-label {
        margin-bottom: 8px;
        font-size: 12px;
        color: #5e6c84;
        line-height: 1.35;
      }

      .html-spec-feedback-textarea {
        width: 100%;
        min-height: 84px;
        resize: vertical;
        border: 1px solid #c1c7d0;
        border-radius: 8px;
        padding: 8px;
        font: inherit;
      }

      .html-spec-feedback-comment-list {
        display: flex;
        flex-direction: column;
        gap: 8px;
      }

      .html-spec-feedback-comment {
        border: 1px solid #dfe1e6;
        border-radius: 10px;
        background: #fafbfc;
        padding: 10px;
      }

      .html-spec-feedback-comment.resolved {
        opacity: 0.62;
      }

      .html-spec-feedback-comment-meta {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        margin-bottom: 6px;
        color: #5e6c84;
        font-size: 12px;
      }

      .html-spec-feedback-comment-text {
        white-space: pre-wrap;
        line-height: 1.35;
      }

      .html-spec-feedback-comment-actions {
        display: flex;
        gap: 6px;
        margin-top: 8px;
      }

      .html-spec-feedback-comment-actions button {
        border: 1px solid #dfe1e6;
        border-radius: 7px;
        background: #ffffff;
        cursor: pointer;
        padding: 4px 7px;
        font-size: 12px;
      }

      .${SELECTED_CLASS} {
        outline: 3px solid #4c9aff !important;
        outline-offset: 3px !important;
      }

      body.html-spec-feedback-mode .canvas *:not(#${UI_ID}):not(#${UI_ID} *) {
        cursor: crosshair;
      }

      .${PIN_CLASS} {
        position: absolute;
        transform: translate(-50%, -50%);
        z-index: 2147483000;
        width: 24px;
        height: 24px;
        border-radius: 999px;
        border: 2px solid #ffffff;
        background: #ff5630;
        color: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: 800;
        box-shadow: 0 3px 10px rgba(9, 30, 66, 0.35);
        cursor: pointer;
      }

      .${PIN_CLASS}.resolved {
        background: #6b778c;
      }
    `;
    document.head.appendChild(style);
  }

  function ensureAnchorIds() {
    const anchorTargets = document.querySelectorAll(
      ".title, .subtitle, .stage, .stage-header, .decision-card, .branch, .branch-title, .strategy-card, .strategy, .note-card, .legend-card, .flow-item, .pill"
    );

    anchorTargets.forEach((element, index) => {
      if (!element.hasAttribute(ANCHOR_ATTR)) {
        const label = textFor(element).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40);
        element.setAttribute(ANCHOR_ATTR, `${element.className.toString().split(" ")[0] || "node"}-${label || index}-${index}`);
      }
    });
  }

  function buildPanel() {
    const root = document.createElement("aside");
    root.id = UI_ID;
    root.innerHTML = `
      <div class="html-spec-feedback-panel">
        <div class="html-spec-feedback-header">
          <span>HTML Spec Feedback</span>
          <button class="html-spec-feedback-icon-button" data-action="collapse" title="Collapse panel">−</button>
        </div>
        <div class="html-spec-feedback-body">
          <div class="html-spec-feedback-actions">
            <button class="html-spec-feedback-button primary" data-action="toggle">Annotate</button>
            <button class="html-spec-feedback-button" data-action="export">Export JSON</button>
            <button class="html-spec-feedback-button" data-action="import">Import JSON</button>
            <button class="html-spec-feedback-button" data-action="clear">Clear local</button>
          </div>
          <div class="html-spec-feedback-help">
            Click <strong>Annotate</strong>, then click a diagram item. Add feedback and export JSON for follow-up fixes. Shortcut: <strong>⌘/Ctrl + Shift + F</strong>.
          </div>
          <div class="html-spec-feedback-composer" data-role="composer">
            <div class="html-spec-feedback-anchor-label" data-role="anchor-label"></div>
            <textarea class="html-spec-feedback-textarea" data-role="comment-text" placeholder="What should change here?"></textarea>
            <div class="html-spec-feedback-comment-actions">
              <button data-action="save-comment">Save comment</button>
              <button data-action="cancel-comment">Cancel</button>
            </div>
          </div>
          <input type="file" accept="application/json" data-role="import-input" hidden />
          <div class="html-spec-feedback-comment-list" data-role="comment-list"></div>
        </div>
      </div>
    `;

    root.addEventListener("click", handlePanelClick);
    root.querySelector("[data-role='import-input']").addEventListener("change", handleImportFile);
    document.body.appendChild(root);
  }

  function handlePanelClick(event) {
    const action = event.target?.dataset?.action;
    if (!action) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();

    if (action === "toggle") {
      setFeedbackMode(!feedbackMode);
    } else if (action === "export") {
      exportFeedback();
    } else if (action === "import") {
      document.querySelector(`#${UI_ID} [data-role='import-input']`).click();
    } else if (action === "clear") {
      clearFeedback();
    } else if (action === "save-comment") {
      saveCurrentComment();
    } else if (action === "cancel-comment") {
      clearSelection();
    } else if (action === "collapse") {
      toggleCollapse(event.target);
    } else if (action === "jump") {
      jumpToComment(event.target.dataset.commentId);
    } else if (action === "resolve") {
      toggleResolved(event.target.dataset.commentId);
    } else if (action === "delete") {
      deleteComment(event.target.dataset.commentId);
    }
  }

  function handleDocumentClick(event) {
    if (!feedbackMode || event.target.closest(`#${UI_ID}`) || event.target.classList.contains(PIN_CLASS)) {
      return;
    }

    const target = event.target.closest(`[${ANCHOR_ATTR}]`);
    if (!target) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    selectElement(target);
  }

  function setFeedbackMode(enabled) {
    feedbackMode = enabled;
    document.body.classList.toggle("html-spec-feedback-mode", enabled);
    const toggle = document.querySelector(`#${UI_ID} [data-action='toggle']`);
    toggle.classList.toggle("active", enabled);
    toggle.textContent = enabled ? "Annotating…" : "Annotate";
    if (!enabled) {
      clearSelection();
    }
  }

  function selectElement(element) {
    clearSelection();
    selectedElement = element;
    selectedElement.classList.add(SELECTED_CLASS);
    const composer = document.querySelector(`#${UI_ID} [data-role='composer']`);
    const label = document.querySelector(`#${UI_ID} [data-role='anchor-label']`);
    const textarea = document.querySelector(`#${UI_ID} [data-role='comment-text']`);
    label.textContent = `Commenting on: ${textFor(element).slice(0, 140)}`;
    textarea.value = "";
    composer.classList.add("visible");
    textarea.focus();
  }

  function saveCurrentComment() {
    const textarea = document.querySelector(`#${UI_ID} [data-role='comment-text']`);
    const content = textarea.value.trim();
    if (!selectedElement || !content) {
      return;
    }

    comments.push({
      id: `fb-${Date.now()}-${Math.random().toString(16).slice(2)}`,
      anchor: buildAnchor(selectedElement),
      content,
      author: "reviewer",
      createdAt: new Date().toISOString(),
      resolved: false,
      replies: []
    });

    persistComments();
    clearSelection();
    renderComments();
  }

  function clearSelection() {
    if (selectedElement) {
      selectedElement.classList.remove(SELECTED_CLASS);
    }
    selectedElement = null;
    const composer = document.querySelector(`#${UI_ID} [data-role='composer']`);
    if (composer) {
      composer.classList.remove("visible");
    }
  }

  function buildAnchor(element) {
    const rect = element.getBoundingClientRect();
    return {
      anchorId: element.getAttribute(ANCHOR_ATTR),
      selector: selectorFor(element),
      text: textFor(element),
      tagName: element.tagName.toLowerCase(),
      className: element.className.toString(),
      boundingClientRect: {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height)
      }
    };
  }

  function renderComments() {
    removePins();
    const list = document.querySelector(`#${UI_ID} [data-role='comment-list']`);
    if (!list) {
      return;
    }

    if (comments.length === 0) {
      list.innerHTML = `<div class="html-spec-feedback-help">No feedback yet.</div>`;
      return;
    }

    list.innerHTML = comments.map((comment, index) => `
      <div class="html-spec-feedback-comment ${comment.resolved ? "resolved" : ""}">
        <div class="html-spec-feedback-comment-meta">
          <strong>#${index + 1} · ${escapeHtml(comment.anchor.text.slice(0, 42))}${comment.anchor.text.length > 42 ? "…" : ""}</strong>
          <span>${comment.resolved ? "Resolved" : "Open"}</span>
        </div>
        <div class="html-spec-feedback-comment-text">${escapeHtml(comment.content)}</div>
        <div class="html-spec-feedback-comment-actions">
          <button data-action="jump" data-comment-id="${comment.id}">Jump</button>
          <button data-action="resolve" data-comment-id="${comment.id}">${comment.resolved ? "Reopen" : "Resolve"}</button>
          <button data-action="delete" data-comment-id="${comment.id}">Delete</button>
        </div>
      </div>
    `).join("");

    comments.forEach((comment, index) => renderPin(comment, index));
  }

  function renderPin(comment, index) {
    const element = findAnchorElement(comment.anchor);
    if (!element) {
      return;
    }
    const rect = element.getBoundingClientRect();
    const pin = document.createElement("button");
    pin.className = `${PIN_CLASS}${comment.resolved ? " resolved" : ""}`;
    pin.type = "button";
    pin.textContent = String(index + 1);
    pin.title = comment.content;
    pin.style.left = `${rect.left + window.scrollX + rect.width - 4}px`;
    pin.style.top = `${rect.top + window.scrollY + 4}px`;
    pin.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      jumpToComment(comment.id);
    });
    document.body.appendChild(pin);
  }

  function removePins() {
    document.querySelectorAll(`.${PIN_CLASS}`).forEach((pin) => pin.remove());
  }

  function jumpToComment(commentId) {
    const comment = comments.find((item) => item.id === commentId);
    if (!comment) {
      return;
    }
    const element = findAnchorElement(comment.anchor);
    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "center" });
      element.classList.add(SELECTED_CLASS);
      setTimeout(() => element.classList.remove(SELECTED_CLASS), 1400);
    }
  }

  function toggleResolved(commentId) {
    comments = comments.map((comment) => comment.id === commentId ? { ...comment, resolved: !comment.resolved } : comment);
    persistComments();
    renderComments();
  }

  function deleteComment(commentId) {
    comments = comments.filter((comment) => comment.id !== commentId);
    persistComments();
    renderComments();
  }

  function exportFeedback() {
    const payload = {
      version: EXPORT_VERSION,
      source: {
        title: document.title,
        path: location.pathname,
        exportedAt: new Date().toISOString()
      },
      comments
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    const safeTitle = document.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "html-spec";
    link.href = url;
    link.download = `${safeTitle}-feedback.json`;
    link.click();
    URL.revokeObjectURL(url);
  }

  function handleImportFile(event) {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const payload = JSON.parse(String(reader.result));
        comments = Array.isArray(payload.comments) ? payload.comments : [];
        persistComments();
        renderComments();
      } catch (error) {
        alert(`Could not import feedback JSON: ${error.message}`);
      }
    };
    reader.readAsText(file);
    event.target.value = "";
  }

  function clearFeedback() {
    if (!confirm("Clear all locally stored feedback for this HTML file?")) {
      return;
    }
    comments = [];
    persistComments();
    renderComments();
  }

  function toggleCollapse(button) {
    const body = document.querySelector(`#${UI_ID} .html-spec-feedback-body`);
    const collapsed = body.style.display === "none";
    body.style.display = collapsed ? "block" : "none";
    button.textContent = collapsed ? "−" : "+";
  }

  function findAnchorElement(anchor) {
    return document.querySelector(`[${ANCHOR_ATTR}='${cssEscape(anchor.anchorId)}']`) ||
      safeQuerySelector(anchor.selector) ||
      Array.from(document.querySelectorAll(`[${ANCHOR_ATTR}]`)).find((element) => textFor(element) === anchor.text);
  }

  function safeQuerySelector(selector) {
    try {
      return selector ? document.querySelector(selector) : null;
    } catch {
      return null;
    }
  }

  function selectorFor(element) {
    const parts = [];
    let current = element;
    while (current && current.nodeType === Node.ELEMENT_NODE && current !== document.body) {
      const anchorId = current.getAttribute(ANCHOR_ATTR);
      if (anchorId) {
        parts.unshift(`[${ANCHOR_ATTR}="${anchorId}"]`);
        break;
      }
      const tag = current.tagName.toLowerCase();
      const parent = current.parentElement;
      if (!parent) {
        parts.unshift(tag);
        break;
      }
      const siblings = Array.from(parent.children).filter((child) => child.tagName === current.tagName);
      const index = siblings.indexOf(current) + 1;
      parts.unshift(siblings.length > 1 ? `${tag}:nth-of-type(${index})` : tag);
      current = parent;
    }
    return parts.join(" > ");
  }

  function textFor(element) {
    return (element.innerText || element.textContent || "").replace(/\s+/g, " ").trim();
  }

  function loadComments() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  }

  function persistComments() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(comments));
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function cssEscape(value) {
    if (window.CSS?.escape) {
      return CSS.escape(value);
    }
    return String(value).replace(/'/g, "\\'");
  }

  window.addEventListener("scroll", () => window.requestAnimationFrame(renderComments), { passive: true });
  window.addEventListener("resize", () => window.requestAnimationFrame(renderComments));

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
