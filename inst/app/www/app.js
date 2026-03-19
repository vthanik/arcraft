/* =============================================================================
   arbuilder — JavaScript (minimal — bslib handles layout switching)
   ============================================================================= */

// --- Variable Card Expand/Collapse ---
function arToggleVarCard(cardId) {
  var card = document.getElementById(cardId);
  if (!card) return;
  var wasOpen = card.classList.contains('ar-var-card--open');
  card.classList.toggle('ar-var-card--open');
  var varName = card.getAttribute('data-var');
  var nsPrefix = cardId.replace('vcard_' + varName, '');
  if (!wasOpen) {
    // Notify R when card opens (for snapshotting pending state)
    if (varName) {
      Shiny.setInputValue(nsPrefix + 'card_opened', {var: varName, ts: Date.now()}, {priority: 'event'});
    }
  } else {
    // Notify R when card closes
    if (varName) {
      Shiny.setInputValue(nsPrefix + 'card_closed', {var: varName, ts: Date.now()}, {priority: 'event'});
    }
  }
}

// --- Variable Row Expand/Collapse (Template sidebar) ---
function arToggleVarRow(rowId) {
  var row = document.getElementById(rowId);
  if (row) row.classList.toggle('ar-varlist-row--open');
}

// --- Fullscreen Toggle ---
function arToggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen();
  } else {
    document.exitFullscreen();
  }
}

// --- Toast Notifications ---
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

// --- Keyboard Shortcuts ---
document.addEventListener('keydown', function(e) {
  // Ctrl+1-5 — click activity bar buttons
  if (e.ctrlKey && !e.shiftKey && !e.altKey) {
    var panels = ['data', 'template', 'analysis', 'format', 'output'];
    var num = parseInt(e.key);
    if (num >= 1 && num <= 5) {
      e.preventDefault();
      var btn = document.getElementById('ab_' + panels[num - 1]);
      if (btn) btn.click();
    }
  }

  // Ctrl+Enter — generate preview
  if (e.ctrlKey && e.key === 'Enter') {
    e.preventDefault();
    var btn = document.getElementById('preview_btn');
    if (btn) btn.click();
  }
});

// --- SortableJS: Variable Card Reorder ---
function arInitVarSortable(containerId) {
  var container = document.getElementById(containerId);
  if (!container) return;

  // Destroy existing instance before re-creating (renderUI replaces DOM)
  if (container._sortable) container._sortable.destroy();

  container._sortable = new Sortable(container, {
    animation: 150,
    handle: '.ar-var-card__drag',
    ghostClass: 'ar-sortable-ghost',
    chosenClass: 'ar-sortable-chosen',
    dragClass: 'ar-sortable-drag',
    onEnd: function() {
      var cards = container.querySelectorAll('.ar-var-card[data-var]');
      var order = Array.from(cards).map(function(c) { return c.getAttribute('data-var'); });
      // Container ID is ns("var_cards") → strip "var_cards" to get ns prefix
      var nsPrefix = containerId.replace('var_cards', '');
      Shiny.setInputValue(nsPrefix + 'var_order', order, {priority: 'event'});
    }
  });
}

// --- SortableJS: Stat Grid Reorder ---
function arInitStatSortable(containerId, varName, nsPrefix) {
  var container = document.getElementById(containerId);
  if (!container) return;

  // Destroy existing instance before re-creating
  if (container._sortable) container._sortable.destroy();

  container._sortable = new Sortable(container, {
    animation: 150,
    handle: '.ar-stat-grid__drag',
    ghostClass: 'ar-sortable-ghost',
    onEnd: function() {
      var rows = container.querySelectorAll('.ar-stat-grid__row[data-stat]');
      var stats = Array.from(rows).map(function(r) { return r.getAttribute('data-stat'); });
      Shiny.setInputValue(nsPrefix + 'stat_order',
        {var: varName, stats: stats}, {priority: 'event'});
    }
  });
}

// --- Disclosure State Preservation ---
// Saves <details> open/closed state before Shiny re-renders, restores after.
var arDisclosureState = {};

$(document).on('shiny:recalculating', function(e) {
  var el = e.target;
  if (!el || !el.querySelectorAll) return;
  el.querySelectorAll('details.ar-disclosure[id]').forEach(function(d) {
    arDisclosureState[d.id] = d.open;
  });
});

$(document).on('shiny:value', function(e) {
  setTimeout(function() {
    var target = document.getElementById(e.name);
    if (!target) return;
    target.querySelectorAll('details.ar-disclosure[id]').forEach(function(d) {
      if (d.id in arDisclosureState) {
        d.open = arDisclosureState[d.id];
      }
    });
  }, 50);
});

// --- Shiny Custom Message Handlers ---
$(document).ready(function() {
  // Toast handler
  Shiny.addCustomMessageHandler('ar_toast', function(data) {
    arToast(data.message, data.type, data.duration);
  });

  // Pipeline dot update handler
  Shiny.addCustomMessageHandler('ar_pipeline_update', function(state) {
    var steps = ['data', 'template', 'analysis', 'format', 'output'];
    steps.forEach(function(step) {
      var dot = document.getElementById('pip_' + step);
      if (!dot) return;
      dot.className = 'ar-pipeline__dot';
      if (state[step] === true) {
        dot.classList.add('ar-pipeline__dot--done');
      }
    });
    // Mark first incomplete step as active
    for (var i = 0; i < steps.length; i++) {
      if (state[steps[i]] !== true) {
        var dot = document.getElementById('pip_' + steps[i]);
        if (dot) dot.classList.add('ar-pipeline__dot--active');
        break;
      }
    }
    // Update connector lines
    steps.forEach(function(step, i) {
      if (i === 0) return;
      var line = document.getElementById('pip_line_' + step);
      if (!line) return;
      line.className = 'ar-pipeline__line';
      if (state[steps[i - 1]] === true) {
        line.classList.add('ar-pipeline__line--done');
      }
    });
  });

  // Init variable card sortable
  Shiny.addCustomMessageHandler('ar_init_var_sortable', function(data) {
    // Delay slightly to let DOM render
    setTimeout(function() {
      arInitVarSortable(data.container_id);
    }, 100);
  });

  // Init stat grid sortable
  Shiny.addCustomMessageHandler('ar_init_stat_sortable', function(data) {
    setTimeout(function() {
      arInitStatSortable(data.container_id, data.var_name, data.ns_prefix);
    }, 100);
  });

  // Init treatment level sortable (drag to reorder arms)
  Shiny.addCustomMessageHandler('ar_init_trt_sortable', function(data) {
    setTimeout(function() {
      var container = document.getElementById(data.container_id);
      if (!container) return;
      if (container._sortable) container._sortable.destroy();
      container._sortable = new Sortable(container, {
        animation: 150,
        handle: '.ar-trt-row__drag',
        ghostClass: 'ar-sortable-ghost',
        chosenClass: 'ar-sortable-chosen',
        dragClass: 'ar-sortable-drag',
        onEnd: function() {
          var rows = container.querySelectorAll('.ar-trt-row[data-level]');
          var order = Array.from(rows).map(function(r) { return r.getAttribute('data-level'); });
          Shiny.setInputValue(data.input_id, order, {priority: 'event'});
        }
      });
    }, 100);
  });

  // Init by-variable level sortable (drag to reorder by-groups)
  Shiny.addCustomMessageHandler('ar_init_by_sortable', function(data) {
    setTimeout(function() {
      var container = document.getElementById(data.container_id);
      if (!container) return;
      if (container._sortable) container._sortable.destroy();
      container._sortable = new Sortable(container, {
        animation: 150,
        handle: '.ar-trt-row__drag',
        ghostClass: 'ar-sortable-ghost',
        chosenClass: 'ar-sortable-chosen',
        dragClass: 'ar-sortable-drag',
        onEnd: function() {
          var blocks = container.querySelectorAll('.ar-by-block[data-level]');
          var order = Array.from(blocks).map(function(b) { return b.getAttribute('data-level'); });
          Shiny.setInputValue(data.input_id, order, {priority: 'event'});
        }
      });
    }, 100);
  });

  // Tab pulse (works with bslib nav-link elements)
  Shiny.addCustomMessageHandler('ar_tab_pulse', function(data) {
    document.querySelectorAll('.nav-link').forEach(function(t) {
      if (t.textContent.trim().toLowerCase().indexOf(data.tab) >= 0) {
        t.classList.add('pulse');
        setTimeout(function() { t.classList.remove('pulse'); }, 3000);
      }
    });
  });

  // Scroll to column in data viewer (partial match + highlight)
  Shiny.addCustomMessageHandler('ar_scroll_to_col', function(data) {
    var headers = document.querySelectorAll('.ar-dv__grid .rt-th');
    var search = data.col.toLowerCase();
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].textContent.toLowerCase().indexOf(search) >= 0) {
        headers[i].scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
        headers[i].style.background = 'var(--accent-muted)';
        (function(el) {
          setTimeout(function() { el.style.background = ''; }, 2000);
        })(headers[i]);
        break;
      }
    }
  });

  // Collapse a variable card by ID
  Shiny.addCustomMessageHandler('ar_collapse_card', function(data) {
    var card = document.getElementById(data.card_id);
    if (card) {
      card.classList.remove('ar-var-card--open');
      var varName = card.getAttribute('data-var');
      if (varName) {
        var nsPrefix = data.card_id.replace('vcard_' + varName, '');
        Shiny.setInputValue(nsPrefix + 'card_closed', {var: varName, ts: Date.now()}, {priority: 'event'});
      }
    }
  });

  // Open a variable card by ID (used to restore state after re-render)
  Shiny.addCustomMessageHandler('ar_open_card', function(data) {
    setTimeout(function() {
      var card = document.getElementById(data.card_id);
      if (card) card.classList.add('ar-var-card--open');
    }, 150);
  });

  // Activity bar unlock (legacy — modules still send this)
  Shiny.addCustomMessageHandler('ar_unlock_step', function(data) {
    // No-op: all panels are now always accessible
  });
});

// Toast container (injected once)
document.addEventListener('DOMContentLoaded', function() {
  if (!document.getElementById('ar_toast_container')) {
    var container = document.createElement('div');
    container.id = 'ar_toast_container';
    document.body.appendChild(container);
  }
});

// --- Format Panel: Preset Active State ---
function arFmtPresetActive(btn) {
  var container = btn.closest('.ar-fmt-preset-pills');
  if (container) {
    container.querySelectorAll('.ar-pill').forEach(function(p) {
      p.classList.remove('ar-pill--active');
    });
  }
  btn.classList.add('ar-pill--active');
}
