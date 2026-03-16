// arbuilder — Builder Layout

// Kill recalculating flash
$(document).on('shiny:recalculating', function(e) {
  $(e.target).css('opacity', '1');
});

// Ctrl+Enter → Generate Preview
$(document).on('keydown', function(e) {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    e.preventDefault();
    $('#preview_btn').click();
  }
});

// ── Accordion Toggle ────────────────────────────────
function arToggleAcc(id) {
  var el = document.getElementById('acc_' + id);
  if (!el) return;
  el.classList.toggle('ar-acc--open');
  // Trigger resize for widgets inside
  setTimeout(function() { window.dispatchEvent(new Event('resize')); }, 100);
}

// ── Canvas Tab Switching ────────────────────────────
function arSwitchTab(tab) {
  document.querySelectorAll('.ar-canvas-tab').forEach(function(t) { t.classList.remove('active'); });
  document.querySelectorAll('.ar-canvas-panel').forEach(function(p) { p.classList.remove('active'); });
  var tabEl = document.getElementById('tab_' + tab);
  var panelEl = document.getElementById('panel_' + tab);
  if (tabEl) tabEl.classList.add('active');
  if (panelEl) panelEl.classList.add('active');
  setTimeout(function() { window.dispatchEvent(new Event('resize')); }, 100);
}

// ── Config Panel Toggle (collapse/expand) ───────────
function arToggleConfig() {
  var el = document.getElementById('ar_config');
  if (el) el.classList.toggle('collapsed');
  setTimeout(function() { window.dispatchEvent(new Event('resize')); }, 250);
}

// ── Data Viewer: show column detail panel ───────────
Shiny.addCustomMessageHandler('ar_show_col_detail', function(msg) {
  var panels = document.querySelectorAll('.ar-dv__col-detail');
  panels.forEach(function(p) { p.classList.remove('ar-dv__col-detail--hidden'); });
});

// ── Data Viewer: scroll to column ───────────────────
Shiny.addCustomMessageHandler('ar_scroll_to_col', function(col) {
  // Find the header cell with matching column name and scroll it into view
  setTimeout(function() {
    var headers = document.querySelectorAll('.ar-dv__grid .rt-th');
    headers.forEach(function(th) {
      if (th.textContent.indexOf(col) !== -1) {
        th.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
      }
    });
  }, 100);
}
