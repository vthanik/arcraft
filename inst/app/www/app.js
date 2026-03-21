/* arbuilder — JavaScript (demographics only)
   Backup of full version: app.js.bak

   Sections:
   1. Variable Card Toggle
   2. Toast Notifications
   3. Keyboard Shortcuts
   4. Resizable Sidebar
   5. Sidebar Collapse
   6. SortableJS Init (generic)
   7. Shiny Message Handlers
   8. DOMContentLoaded Setup
*/

/* ── 1. Variable Card Toggle ── */
function arToggleVarCard(cardId) {
  var card = document.getElementById(cardId);
  if (!card) return;
  card.classList.toggle('ar-var-card--open');
  var varName = card.getAttribute('data-var');
  if (!varName) return;
  var nsPrefix = cardId.replace('vcard_' + varName, '');
  var isOpen = card.classList.contains('ar-var-card--open');
  var eventName = isOpen ? 'card_opened' : 'card_closed';
  Shiny.setInputValue(nsPrefix + eventName, {var: varName, ts: Date.now()}, {priority: 'event'});
}

/* ── 2. Toast Notifications ── */
function arToast(message, type, duration) {
  type = type || 'success';
  duration = duration || 3000;
  var container = document.getElementById('ar_toast_container');
  if (!container) return;
  var icons = { success: '&#10003;', warning: '&#9888;', error: '&#10007;' };
  var toast = document.createElement('div');
  toast.className = 'ar-toast ar-toast--' + type;
  toast.innerHTML = '<span class="ar-toast__icon">' + (icons[type] || '') + '</span>' +
                    '<span class="ar-toast__message">' + message + '</span>';
  container.appendChild(toast);
  setTimeout(function() {
    toast.style.animation = 'ar-toast-out 0.3s ease forwards';
    setTimeout(function() { toast.remove(); }, 300);
  }, duration);
}

/* ── 3. Keyboard Shortcuts ── */
document.addEventListener('keydown', function(e) {
  /* Ctrl+1-5: switch activity bar tabs */
  if (e.ctrlKey && !e.shiftKey && !e.altKey) {
    var panels = ['data', 'template', 'analysis', 'format', 'output'];
    var num = parseInt(e.key);
    if (num >= 1 && num <= 5) {
      e.preventDefault();
      var btn = document.getElementById('ab_' + panels[num - 1]);
      if (btn) btn.click();
    }
  }
  /* Ctrl+Enter: generate preview */
  if (e.ctrlKey && e.key === 'Enter') { e.preventDefault(); var btn = document.getElementById('preview_btn'); if (btn) btn.click(); }
  /* Ctrl+S: export RTF */
  if (e.ctrlKey && !e.shiftKey && e.key === 's') { e.preventDefault(); var dl = document.getElementById('export_rtf'); if (dl) dl.click(); }
  /* Ctrl+Shift+S: download R script */
  if (e.ctrlKey && e.shiftKey && e.key === 'S') { e.preventDefault(); var dl = document.getElementById('dl_script'); if (dl) dl.click(); }
  /* Escape: collapse all open cards */
  if (e.key === 'Escape') {
    document.querySelectorAll('.ar-var-card--open').forEach(function(c) { c.classList.remove('ar-var-card--open'); });
    document.querySelectorAll('.ar-col-item__body--open').forEach(function(b) {
      b.classList.remove('ar-col-item__body--open');
      var h = b.previousElementSibling;
      if (h) { var ch = h.querySelector('.ar-col-item__chevron'); if (ch) ch.classList.remove('ar-col-item__chevron--open'); }
    });
  }
  /* Ctrl+B: toggle sidebar */
  if (e.ctrlKey && e.key === 'b') { e.preventDefault(); arToggleSidebar(); }
});

/* ── 4. Resizable Sidebar ── */
(function() {
  var handle, sidebar, isResizing = false, startX, startWidth;
  document.addEventListener('DOMContentLoaded', function() {
    handle = document.getElementById('ar_resize_handle');
    sidebar = document.querySelector('.ar-sidebar');
    if (!handle || !sidebar) return;
    handle.addEventListener('mousedown', function(e) {
      isResizing = true; startX = e.clientX; startWidth = sidebar.offsetWidth;
      handle.classList.add('ar-resize-handle--active');
      document.body.style.cursor = 'col-resize'; document.body.style.userSelect = 'none';
      e.preventDefault();
    });
    document.addEventListener('mousemove', function(e) {
      if (!isResizing) return;
      var w = Math.max(260, Math.min(500, startWidth + e.clientX - startX));
      sidebar.style.width = w + 'px'; sidebar.style.transition = 'none';
    });
    document.addEventListener('mouseup', function() {
      if (!isResizing) return;
      isResizing = false; handle.classList.remove('ar-resize-handle--active');
      document.body.style.cursor = ''; document.body.style.userSelect = '';
      sidebar.style.transition = '';
    });
    handle.addEventListener('dblclick', arToggleSidebar);
  });
})();

/* ── 5. Sidebar Collapse ── */
function arToggleSidebar() {
  var sidebar = document.querySelector('.ar-sidebar');
  var handle = document.getElementById('ar_resize_handle');
  if (!sidebar) return;
  var collapsed = sidebar.classList.toggle('ar-sidebar--collapsed');
  if (handle) handle.style.display = collapsed ? 'none' : '';
}

/* ── 6. SortableJS Init (generic) ── */
function arInitSortable(containerId, handleClass, itemSelector, attrName, inputId) {
  var el = document.getElementById(containerId);
  if (!el) return;
  if (el._sortable) el._sortable.destroy();
  el._sortable = new Sortable(el, {
    animation: 150, handle: handleClass,
    ghostClass: 'ar-sortable-ghost', chosenClass: 'ar-sortable-chosen', dragClass: 'ar-sortable-drag',
    onEnd: function() {
      var items = el.querySelectorAll(itemSelector);
      var order = Array.from(items).map(function(i) { return i.getAttribute(attrName); });
      Shiny.setInputValue(inputId, order, {priority: 'event'});
    }
  });
}

/* ── 7. Shiny Message Handlers ── */
$(document).ready(function() {
  /* Toast */
  Shiny.addCustomMessageHandler('ar_toast', function(d) { arToast(d.message, d.type, d.duration); });

  /* Pipeline badges + status pill */
  Shiny.addCustomMessageHandler('ar_pipeline_update', function(state) {
    var steps = ['data', 'template', 'analysis', 'format', 'output'];
    var first = null;
    steps.forEach(function(s) {
      var b = document.getElementById('ab_badge_' + s);
      if (!b) return;
      b.className = 'ar-ab-badge';
      if (state[s] === true) b.classList.add('ar-ab-badge--done');
    });
    for (var i = 0; i < steps.length; i++) {
      if (state[steps[i]] !== true) {
        first = steps[i];
        var b = document.getElementById('ab_badge_' + steps[i]);
        if (b) b.className = 'ar-ab-badge ar-ab-badge--active';
        break;
      }
    }
    var pill = document.getElementById('ar_status_pill');
    if (pill) {
      var t = pill.querySelector('.ar-status-pill__text');
      pill.className = 'ar-status-pill';
      if (!first) { pill.classList.add('ar-status-pill--ready'); if (t) t.textContent = 'Ready to export'; }
      else { pill.classList.add('ar-status-pill--needs-config');
        var hints = { data: 'Load data to start', template: 'Select a template', analysis: 'Configure analysis', format: 'Generate preview', output: 'Generate preview' };
        if (t) t.textContent = hints[first] || 'Configure';
      }
    }
  });

  /* Variable card sortable */
  Shiny.addCustomMessageHandler('ar_init_var_sortable', function(d) {
    setTimeout(function() {
      var cid = d.container_id;
      var ns = cid.replace('var_cards', '');
      arInitSortable(cid, '.ar-var-card__drag', '.ar-var-card[data-var]', 'data-var', ns + 'var_order');
    }, 100);
  });

  /* Stat grid sortable */
  Shiny.addCustomMessageHandler('ar_init_stat_sortable', function(d) {
    setTimeout(function() {
      var el = document.getElementById(d.container_id);
      if (!el) return;
      if (el._sortable) el._sortable.destroy();
      el._sortable = new Sortable(el, {
        animation: 150, handle: '.ar-stat-grid__drag', ghostClass: 'ar-sortable-ghost',
        onEnd: function() {
          var rows = el.querySelectorAll('.ar-stat-grid__row[data-stat]');
          var stats = Array.from(rows).map(function(r) { return r.getAttribute('data-stat'); });
          Shiny.setInputValue(d.ns_prefix + 'stat_order', {var: d.var_name, stats: stats}, {priority: 'event'});
        }
      });
    }, 100);
  });

  /* Treatment level sortable */
  /* Robust sortable init — retries until element exists */
  function arInitSortableRetry(containerId, handleClass, itemSelector, attrName, inputId) {
    var attempts = 0;
    function tryInit() {
      var el = document.getElementById(containerId);
      if (el && el.children.length > 0) {
        arInitSortable(containerId, handleClass, itemSelector, attrName, inputId);
      } else if (attempts < 10) {
        attempts++;
        setTimeout(tryInit, 200);
      }
    }
    setTimeout(tryInit, 100);
  }

  Shiny.addCustomMessageHandler('ar_init_trt_sortable', function(d) {
    arInitSortableRetry(d.container_id, '.ar-trt-row__drag', '.ar-trt-row[data-level]', 'data-level', d.input_id);
  });

  Shiny.addCustomMessageHandler('ar_init_by_sortable', function(d) {
    arInitSortableRetry(d.container_id, '.ar-trt-row__drag', '.ar-trt-row[data-level]', 'data-level', d.input_id);
  });

  Shiny.addCustomMessageHandler('ar_init_level_sortable', function(d) {
    arInitSortableRetry(d.container_id, '.ar-trt-row__drag', '.ar-trt-row[data-level]', 'data-level', d.input_id);
  });

  /* Collapse/open variable cards */
  Shiny.addCustomMessageHandler('ar_collapse_card', function(d) {
    var card = document.getElementById(d.card_id);
    if (!card) return;
    card.classList.remove('ar-var-card--open');
    var v = card.getAttribute('data-var');
    if (v) { var ns = d.card_id.replace('vcard_' + v, ''); Shiny.setInputValue(ns + 'card_closed', {var: v, ts: Date.now()}, {priority: 'event'}); }
  });
  Shiny.addCustomMessageHandler('ar_open_card', function(d) {
    var c = document.getElementById(d.card_id);
    if (c) setTimeout(function() { c.classList.add('ar-var-card--open'); }, 150);
  });

  /* Accordion status dots */
  Shiny.addCustomMessageHandler('ar_acc_dots', function(d) {
    var dots = d.dots || d;
    var map = d.map || {};
    Object.keys(dots).forEach(function(k) {
      var title = map[k]; if (!title) return;
      var btns = document.querySelectorAll('.ar-sidebar .accordion-button');
      for (var i = 0; i < btns.length; i++) {
        if (btns[i].textContent.trim().indexOf(title) === 0) {
          var dot = btns[i].querySelector('.ar-acc-dot');
          if (!dot) { dot = document.createElement('span'); dot.className = 'ar-acc-dot'; btns[i].appendChild(dot); }
          dot.className = 'ar-acc-dot';
          if (dots[k] === 'done') dot.classList.add('ar-acc-dot--done');
          else if (dots[k] === 'active') dot.classList.add('ar-acc-dot--active');
          break;
        }
      }
    });
  });

  /* Scroll to column in data viewer (mod_data_viewer.R) */
  Shiny.addCustomMessageHandler('ar_scroll_to_col', function(d) {
    var headers = document.querySelectorAll('.ar-dv__grid .rt-th');
    var search = d.col.toLowerCase();
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].textContent.toLowerCase().indexOf(search) >= 0) {
        headers[i].scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
        headers[i].style.background = 'var(--accent-muted)';
        (function(el) { setTimeout(function() { el.style.background = ''; }, 2000); })(headers[i]);
        break;
      }
    }
  });

  /* Toggle element visibility (replaces shinyjs::toggle) */
  Shiny.addCustomMessageHandler('ar_toggle', function(d) {
    var el = document.getElementById(d.id);
    if (el) {
      if (d.show) { el.classList.remove('ar-hidden'); el.style.display = ''; }
      else { el.classList.add('ar-hidden'); el.style.display = ''; }
    }
  });

  /* Switch activity bar panel (replaces shinyjs::runjs) */
  Shiny.addCustomMessageHandler('ar_switch_panel', function(d) {
    document.querySelectorAll('.ar-ab-btn').forEach(function(b) { b.classList.remove('active'); });
    var btn = document.getElementById('ab_' + d.panel);
    if (btn) btn.classList.add('active');
  });

  /* Debounced preview trigger (replaces shinyjs::delay + click) */
  var _previewTimer = null;
  Shiny.addCustomMessageHandler('ar_debounce_preview', function(d) {
    if (_previewTimer) clearTimeout(_previewTimer);
    _previewTimer = setTimeout(function() {
      var btn = document.getElementById('preview_btn');
      if (btn) btn.click();
      _previewTimer = null;
    }, d.delay || 800);
  });

});

/* ── 8. DOMContentLoaded Setup ── */
document.addEventListener('DOMContentLoaded', function() {
  /* Toast container */
  if (!document.getElementById('ar_toast_container')) {
    var c = document.createElement('div'); c.id = 'ar_toast_container'; document.body.appendChild(c);
  }
  /* Double-click activity bar icon to toggle sidebar */
  var lastClick = {};
  document.querySelectorAll('.ar-ab-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      var now = Date.now();
      if (lastClick[btn.id] && now - lastClick[btn.id] < 350) {
        arToggleSidebar();
        delete lastClick[btn.id];
      } else {
        lastClick[btn.id] = now;
      }
    });
  });
});

/* Format preset active state */
function arFmtPresetActive(btn) {
  var p = btn.closest('.ar-fmt-preset-pills');
  if (p) p.querySelectorAll('.ar-pill').forEach(function(x) { x.classList.remove('ar-pill--active'); });
  btn.classList.add('ar-pill--active');
}

