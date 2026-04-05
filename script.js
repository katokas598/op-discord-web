const navButtons = document.querySelectorAll('.nav-btn');
const views = document.querySelectorAll('.panel-view');
const status = document.getElementById('status');
const configForm = document.getElementById('config-form');
const commandForm = document.getElementById('command-form');
const refreshAll = document.getElementById('refresh-all');

const api = async (path, options = {}) => {
  const response = await fetch(path, options);
  return response.json();
};

const renderCards = (el, items, renderItem, emptyText) => {
  if (!el) return;
  el.innerHTML = items.length ? items.map(renderItem).join('') : `<div class="glass card-empty">${emptyText}</div>`;
};

const loadDashboard = async () => {
  const [members, tickets, logs, settings, commands] = await Promise.all([
    api('/api/members'),
    api('/api/tickets'),
    api('/api/mod-logs'),
    api('/api/settings'),
    api('/api/custom-commands'),
  ]);

  renderCards(
    document.getElementById('members-list'),
    members.members || [],
    (item) => `<article class="glass admin-card"><h3>${item.name || item.id}</h3><p>ID: ${item.id}</p><div class="hero-actions"><button class="btn btn-primary btn-mini" data-action="ban" data-user="${item.id}">Бан</button><button class="btn btn-secondary btn-mini" data-action="kick" data-user="${item.id}">Кик</button><button class="btn btn-secondary btn-mini" data-action="mute" data-user="${item.id}">Мут</button><button class="btn btn-secondary btn-mini" data-action="warn" data-user="${item.id}">Warn</button></div></article>`,
    'Пользователи пока не загружены.'
  );

  renderCards(
    document.getElementById('tickets-list'),
    tickets.tickets || [],
    (item) => `<article class="glass admin-card"><h3>Тикет #${item.id}</h3><p>Пользователь: ${item.user_id}</p><p>Категория: ${item.category || '—'}</p><p>Статус: ${item.status || 'open'}</p><form class="ticket-reply" data-ticket="${item.id}"><input name="message" placeholder="Ответить в тикет" /><div class="hero-actions"><button class="btn btn-primary btn-mini" type="submit">Ответить</button><button class="btn btn-secondary btn-mini" type="button" data-close-ticket="${item.id}">Закрыть</button></div></form></article>`,
    'Тикеты пока не найдены.'
  );

  renderCards(
    document.getElementById('logs-list'),
    logs.logs || [],
    (item) => `<article class="glass admin-card"><h3>${item.action}</h3><p>Пользователь: ${item.user_id}</p><p>Причина: ${item.reason || '-'}</p><p>Модератор: ${item.moderator_id}</p></article>`,
    'Логи пока пустые.'
  );

  renderCards(
    document.getElementById('commands-list'),
    commands.commands || [],
    (item) => `<article class="glass admin-card"><h3>/${item.name}</h3><p>${item.response}</p></article>`,
    'Кастомных команд пока нет.'
  );

  const settingsView = document.getElementById('settings-view');
  if (settingsView) {
    const cfg = settings.settings || {};
    settingsView.innerHTML = `
      <div class="settings-grid">
        <div class="stat-card glass"><span>Prefix</span><strong>${cfg.prefix || '!'}</strong></div>
        <div class="stat-card glass"><span>Max warns</span><strong>${cfg.max_warns || 3}</strong></div>
        <div class="stat-card glass"><span>Server ID</span><strong>${cfg.guild_id || '—'}</strong></div>
      </div>
    `;
  }
};

navButtons.forEach((button) => {
  button.addEventListener('click', () => {
    navButtons.forEach((b) => b.classList.remove('active'));
    views.forEach((v) => v.classList.remove('active'));
    button.classList.add('active');
    const view = document.getElementById(button.dataset.view);
    if (view) view.classList.add('active');
  });
});

if (configForm) {
  configForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const body = new URLSearchParams(new FormData(configForm));
    const result = await api('/save-config', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
    if (status) status.textContent = result.ok ? 'Настройки сохранены.' : 'Ошибка сохранения.';
    loadDashboard();
  });
}

if (commandForm) {
  commandForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const body = new URLSearchParams(new FormData(commandForm));
    await api('/api/custom-commands', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
    commandForm.reset();
    loadDashboard();
  });
}

if (refreshAll) refreshAll.addEventListener('click', loadDashboard);

document.addEventListener('submit', async (event) => {
  const form = event.target.closest('.ticket-reply');
  if (!form) return;
  event.preventDefault();
  const body = new URLSearchParams({ ticket_id: form.dataset.ticket, message: form.message.value });
  await api('/api/tickets/reply', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
  loadDashboard();
});

document.addEventListener('click', async (event) => {
  const btn = event.target.closest('[data-action]');
  if (btn) {
    const body = new URLSearchParams({ action: btn.dataset.action, user_id: btn.dataset.user || '', reason: 'WEB_PANEL' });
    await api('/api/action', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
    loadDashboard();
    return;
  }

  const closeBtn = event.target.closest('[data-close-ticket]');
  if (closeBtn) {
    const body = new URLSearchParams({ ticket_id: closeBtn.dataset.closeTicket });
    await api('/api/tickets/close', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
    loadDashboard();
  }
});

const revealItems = document.querySelectorAll('.reveal');
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });
revealItems.forEach((item) => observer.observe(item));

loadDashboard();
