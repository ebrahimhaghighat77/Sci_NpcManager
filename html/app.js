(function () {
	'use strict';

	function resourceName() {
		try {
			var fn = window.GetParentResourceName;
			return fn ? fn() : 'Sci_NpcManager';
		} catch (e) {
			return 'Sci_NpcManager';
		}
	}

	function nui(endpoint, data, done) {
		try {
			fetch('https://' + resourceName() + '/' + endpoint, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(data || {})
			})
				.then(function (r) { return r.json(); })
				.then(function (r) { if (done) done(r || {}); })
				.catch(function () { if (done) done({ err: 'no_response' }); });
		} catch (e) {
			if (done) done({ err: 'no_response' });
		}
	}

	var DENSITY = [
		{ key: 'peds', label: 'Pedestrians', hint: 'People walking the pavements' },
		{ key: 'scenarios', label: 'Scenario peds', hint: 'Sitting on benches, smoking, jogging, vending' },
		{ key: 'vehicles', label: 'Traffic', hint: 'Moving cars; also shrinks the range they spawn at' },
		{ key: 'parked', label: 'Parked cars', hint: 'Cars left along kerbs and in car parks' }
	];

	var SYSTEMS = [
		{ key: 'cops', label: 'Police', hint: 'Ambient patrols, scenario cops and distant sirens' },
		{ key: 'garbage', label: 'Garbage trucks', hint: 'Bin lorries on their rounds' },
		{ key: 'boats', label: 'Boats', hint: 'Ambient boats on the water' },
		{ key: 'trains', label: 'Trains', hint: 'Freight and metro trains' },
		{ key: 'wildlife', label: 'Wildlife', hint: 'Deer, coyotes, birds, pets and the rest' }
	];

	var SWEEP = [
		{ key: 'purge', label: 'Keep sweeping pedestrians', hint: 'Deletes ambient peds already out, every sweep interval' },
		{ key: 'purgeCars', label: 'Keep sweeping traffic', hint: 'Ambient cars only; player and script vehicles are never touched' }
	];

	var PAGES = {
		density: { title: 'Density', sub: 'How many peds and cars the game spawns' },
		systems: { title: 'Ambient systems', sub: 'What the game may spawn at all' },
		sweep: { title: 'Sweep', sub: 'Remove what has already spawned' },
		presets: { title: 'Presets', sub: 'One click to a known state' }
	};

	var ERRORS = {
		no_permission: 'You do not have permission to do that.',
		too_fast: 'Slow down.',
		unknown_preset: 'That preset no longer exists.',
		bad_request: 'The server rejected that change.',
		no_response: 'The server did not answer.'
	};

	var ICONS = {
		alert: '<path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>',
		check: '<path d="M20 6 9 17l-5-5"/>',
		wind: '<path d="M9.59 4.59A2 2 0 1 1 11 8H2"/><path d="M12.59 19.41A2 2 0 1 0 14 16H2"/><path d="M17.73 7.73A2.5 2.5 0 1 1 19.5 12H2"/>'
	};

	var S = { data: null, draft: null, page: 'density', timer: null, dragging: false, stats: null };

	var el = {
		scrim: document.getElementById('scrim'),
		content: document.getElementById('content'),
		nav: document.getElementById('nav'),
		title: document.getElementById('pageTitle'),
		sub: document.getElementById('pageSub'),
		pill: document.getElementById('statusPill'),
		master: document.getElementById('master'),
		masterSub: document.getElementById('masterSub'),
		masterToggle: document.getElementById('masterToggle'),
		brandTag: document.getElementById('brandTag'),
		brandTitle: document.getElementById('brandTitle'),
		brandSub: document.getElementById('brandSub'),
		brandLogo: document.getElementById('brandLogo'),
		brandLogoImg: document.getElementById('brandLogoImg'),
		toast: document.getElementById('toast')
	};

	var THEME_VARS = {
		accent: '--accent', accentDeep: '--accent-2', accentSoft: '--accent-soft',
		stroke: '--stroke', strokeSoft: '--stroke-2',
		text: '--txt', textDim: '--txt-2', textFaint: '--txt-3',
		ok: '--ok', warn: '--warn', bad: '--bad', font: '--font', scrim: '--scrim'
	};

	function hexToRgb(hex) {
		var m = typeof hex === 'string' && hex.replace(/\s/g, '').match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
		if (!m) return null;

		var h = m[1].length === 3 ? m[1].replace(/(.)/g, '$1$1') : m[1];
		return { r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16) };
	}

	function applyTheme(theme) {
		if (!theme) return;
		var root = document.documentElement.style;

		for (var key in THEME_VARS) {
			var value = theme[key];
			if (value !== undefined && value !== null && value !== '') root.setProperty(THEME_VARS[key], String(value));
		}

		if (theme.panelFrom && theme.panelTo) {
			root.setProperty('--glass', 'linear-gradient(150deg,' + theme.panelFrom + ',' + theme.panelTo + ')');
		}
		if (theme.cardFrom && theme.cardTo) {
			root.setProperty('--glass-2', 'linear-gradient(150deg,' + theme.cardFrom + ',' + theme.cardTo + ')');
		}

		function wash(hex, alpha, prop) {
			var rgb = hexToRgb(hex);
			if (rgb) root.setProperty(prop, 'rgba(' + rgb.r + ',' + rgb.g + ',' + rgb.b + ',' + alpha + ')');
		}

		if (!theme.accentSoft) wash(theme.accent, '.14', '--accent-soft');
		wash(theme.ok, '.16', '--ok-fill');
		wash(theme.bad, '.16', '--bad-fill');
		wash(theme.warn, '.09', '--warn-fill');
		wash(theme.warn, '.30', '--warn-line');

		var rgb = hexToRgb(theme.accent);
		if (rgb) {
			var lift = function (c) { return Math.round(c + (255 - c) * 0.45); };
			root.setProperty('--accent-text', 'rgb(' + lift(rgb.r) + ',' + lift(rgb.g) + ',' + lift(rgb.b) + ')');
		}

		if (theme.radius != null) root.setProperty('--r', parseFloat(theme.radius) + 'px');
		if (theme.radiusSmall != null) root.setProperty('--r-sm', parseFloat(theme.radiusSmall) + 'px');
	}

	function applyBrand(brand) {
		brand = brand || {};

		el.brandTitle.textContent = brand.title || 'NPC Manager';
		el.brandSub.textContent = brand.name || '';
		document.title = brand.title || 'NPC Manager';

		var tag = String(brand.tag || 'SN');
		el.brandTag.textContent = tag.replace(/[^A-Z]/g, '').slice(0, 2) || tag.replace(/\s/g, '').slice(0, 2).toUpperCase();

		var logo = brand.logo ? String(brand.logo) : '';
		var img = el.brandLogoImg;
		if (logo && img.getAttribute('src') === logo) return;

		img.hidden = true;
		el.brandLogo.classList.remove('has-img');

		if (!logo) return img.removeAttribute('src');

		img.onload = function () {
			img.hidden = false;
			el.brandLogo.classList.add('has-img');
		};
		img.onerror = function () {
			console.warn('[Sci_NpcManager] Config.Brand.logo did not load:', logo);
		};
		img.src = logo;
	}

	function esc(value) {
		return String(value == null ? '' : value).replace(/[&<>"']/g, function (c) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
		});
	}

	function icon(name) {
		return '<svg class="sci-ico" viewBox="0 0 24 24">' + ICONS[name] + '</svg>';
	}

	function copy(obj) {
		var out = {};
		for (var key in obj) out[key] = obj[key];
		return out;
	}

	function current() {
		return S.draft || (S.data && S.data.settings) || {};
	}

	function fill(value) {
		return Math.round(Math.max(0, Math.min(3, value)) / 3 * 100) + '%';
	}

	function toast(message, kind) {
		el.toast.textContent = message;
		el.toast.className = 'sci-toast show' + (kind ? ' ' + kind : '');
		clearTimeout(el.toast._t);
		el.toast._t = setTimeout(function () { el.toast.className = 'sci-toast'; }, 2600);
	}

	function failed(reply) {
		toast(ERRORS[reply && reply.err] || 'Something went wrong.', 'bad');
	}

	function toggleRow(item, s) {
		return '<div class="sci-trow"><div class="sci-trow-txt">' +
			'<div class="sci-trow-l">' + esc(item.label) + '</div><div class="sci-trow-h">' + esc(item.hint) + '</div></div>' +
			'<button class="sci-toggle' + (s[item.key] ? ' on' : '') + '" data-toggle="' + item.key + '"></button></div>';
	}

	function stat(value, label, id) {
		return '<div class="sci-stat"><div class="sci-stat-v"' + (id ? ' id="' + id + '"' : '') + '>' + esc(value) + '</div>' +
			'<div class="sci-stat-k">' + esc(label) + '</div></div>';
	}

	function offNotice(s) {
		if (s.enabled) return '';
		return '<div class="sci-warn">' + icon('alert') + '<div>Population control is off, so the game uses its own ' +
			'defaults. Nothing here applies until the switch in the sidebar is back on.</div></div>';
	}

	function pageDensity(s, d) {
		var chips = [];
		if (d.factor < 1) chips.push('Auto-scale ' + Math.round(d.factor * 100) + '% at ' + d.players + ' players');
		if (d.schedule) chips.push('Time schedule on');
		if (d.zones > 0) chips.push(d.zones + (d.zones === 1 ? ' zone override' : ' zone overrides'));

		var rows = DENSITY.map(function (item) {
			var value = Number(s[item.key]) || 0;
			return '<div class="sci-srow"><div class="sci-srow-h"><div>' +
				'<div class="sci-trow-l">' + esc(item.label) + '</div><div class="sci-trow-h">' + esc(item.hint) + '</div></div>' +
				'<div class="sci-srow-v" id="v_' + item.key + '">' + value.toFixed(2) + '</div></div>' +
				'<input class="sci-range" type="range" min="0" max="3" step="0.05" value="' + value + '" data-range="' +
				item.key + '" style="--fill:' + fill(value) + '"></div>';
		}).join('');

		return offNotice(s) +
			(chips.length ? '<div class="sci-sec-h"><div class="sci-hint">Also shaping what players see</div><div class="sci-chips">' +
				chips.map(function (c) { return '<span class="sci-tag">' + esc(c) + '</span>'; }).join('') + '</div></div>' : '') +
			'<div class="sci-card">' + rows + '</div>' +
			'<div class="sci-hint">1.00 is stock GTA. Past about 1.50 the engine\'s population budget limits the crowd, not the slider.</div>';
	}

	function pageSystems(s) {
		return offNotice(s) + '<div class="sci-card">' + SYSTEMS.map(function (i) { return toggleRow(i, s); }).join('') + '</div>' +
			'<div class="sci-hint">Switching one off stops new spawns; use Sweep to clear what is already out.</div>';
	}

	function pageSweep(s) {
		return offNotice(s) +
			'<div class="sci-live">' +
				['stPeds:Peds streamed', 'stVeh:Vehicles streamed', 'stZone:Zone', 'stHour:In-game hour'].map(function (p) {
					var parts = p.split(':');
					return '<div class="sci-card">' + stat('-', parts[1], parts[0]) + '</div>';
				}).join('') +
			'</div>' +
			'<div class="sci-card">' + SWEEP.map(function (i) { return toggleRow(i, s); }).join('') + '</div>' +
			'<div class="sci-sec-h"><div class="sci-hint">Script-created NPCs, player vehicles and protected zones are never swept.</div>' +
			'<button class="sci-btn primary" data-act="sweep">' + icon('wind') + 'Sweep now</button></div>';
	}

	function matches(preset, s) {
		var p = preset.settings || {};
		for (var key in p) if (p[key] !== s[key]) return false;
		return true;
	}

	function pagePresets(s, d) {
		return '<div class="sci-presets">' + (d.presets || []).map(function (p) {
			var st = p.settings || {};
			var on = matches(p, s);
			var num = function (v) { return typeof v === 'number' ? v.toFixed(2) : '-'; };

			return '<div class="sci-preset' + (on ? ' on' : '') + '">' +
				'<div class="sci-preset-t">' + esc(p.label) + '</div><div class="sci-preset-d">' + esc(p.desc) + '</div>' +
				'<div class="sci-preset-s">' + stat(num(st.peds), 'Peds') + stat(num(st.vehicles), 'Traffic') + stat(num(st.parked), 'Parked') + '</div>' +
				(on ? '<button class="sci-btn sci-full is-active">' + icon('check') + 'Active</button>'
					: '<button class="sci-btn primary sci-full" data-preset="' + esc(p.id) + '">Apply</button>') +
				'</div>';
		}).join('') + '</div>';
	}

	function paintStats() {
		var d = S.stats;
		if (!d || S.page !== 'sweep') return;

		var set = function (id, v) { var n = document.getElementById(id); if (n) n.textContent = v; };
		set('stPeds', d.peds);
		set('stVeh', d.vehicles);
		set('stZone', d.zone || 'None');
		set('stHour', (d.hour < 10 ? '0' : '') + d.hour + ':00');
	}

	function renderChrome() {
		var s = current();

		el.pill.className = 'sci-pill ' + (s.enabled ? 'on' : 'off');
		el.pill.innerHTML = '<span class="dot"></span>' + (s.enabled ? 'Active' : 'Off');
		el.master.className = 'sci-master' + (s.enabled ? ' on' : '');
		el.masterToggle.className = 'sci-toggle' + (s.enabled ? ' on' : '');
		el.masterSub.textContent = s.enabled ? 'Overriding the game' : 'Game defaults';

		el.title.textContent = PAGES[S.page].title;
		el.sub.textContent = PAGES[S.page].sub;

		var items = el.nav.querySelectorAll('[data-page]');
		for (var i = 0; i < items.length; i++) {
			items[i].classList.toggle('active', items[i].getAttribute('data-page') === S.page);
		}
	}

	function render() {
		if (!S.data) return;
		var s = current();

		renderChrome();

		el.content.innerHTML = S.page === 'systems' ? pageSystems(s)
			: S.page === 'sweep' ? pageSweep(s)
			: S.page === 'presets' ? pagePresets(s, S.data)
			: pageDensity(s, S.data);

		paintStats();
	}

	function switchPage(page) {
		if (!PAGES[page] || page === S.page) return;
		S.page = page;
		render();
		el.content.scrollTop = 0;
		el.content.style.animation = 'none';
		void el.content.offsetWidth;
		el.content.style.animation = '';
	}

	function edit(key, value) {
		S.draft = S.draft || copy(S.data.settings);
		S.draft[key] = value;
		clearTimeout(S.timer);
		S.timer = setTimeout(push, 300);
	}

	function push() {
		clearTimeout(S.timer);
		S.timer = null;
		if (!S.draft) return;

		nui('apply', S.draft, function (reply) {
			if (reply.ok && reply.data) S.data = reply.data;
			else failed(reply);

			if (!S.timer && !S.dragging) {
				S.draft = null;
				render();
			}
		});
	}

	el.nav.addEventListener('click', function (ev) {
		var item = ev.target.closest('[data-page]');
		if (item) switchPage(item.getAttribute('data-page'));
	});

	el.masterToggle.addEventListener('click', function () {
		edit('enabled', !current().enabled);
		render();
	});

	el.content.addEventListener('click', function (ev) {
		var toggle = ev.target.closest('[data-toggle]');
		if (toggle) {
			var key = toggle.getAttribute('data-toggle');
			edit(key, !current()[key]);
			render();
			return;
		}

		var preset = ev.target.closest('[data-preset]');
		if (preset) {
			clearTimeout(S.timer);
			S.timer = null;
			nui('preset', { id: preset.getAttribute('data-preset') }, function (reply) {
				if (!reply.ok) return failed(reply);
				S.data = reply.data;
				S.draft = null;
				render();
				toast('Preset applied', 'ok');
			});
			return;
		}

		if (ev.target.closest('[data-act="sweep"]')) {
			nui('purge', {}, function (reply) {
				if (reply.ok) toast('Sweep sent to every player', 'ok');
				else failed(reply);
			});
		}
	});

	el.content.addEventListener('input', function (ev) {
		var range = ev.target;
		if (!range.matches('[data-range]')) return;

		var value = Number(range.value);
		S.dragging = true;
		range.style.setProperty('--fill', fill(value));
		document.getElementById('v_' + range.getAttribute('data-range')).textContent = value.toFixed(2);
	});

	el.content.addEventListener('change', function (ev) {
		var range = ev.target;
		if (!range.matches('[data-range]')) return;

		S.dragging = false;
		edit(range.getAttribute('data-range'), Number(range.value));
	});

	function close() {
		if (S.timer) push();
		nui('close', {});
	}

	document.getElementById('closeBtn').addEventListener('click', close);

	document.addEventListener('keydown', function (ev) {
		if (ev.key === 'Escape' && el.scrim.classList.contains('open')) close();
	});

	window.addEventListener('message', function (event) {
		var msg = event.data || {};

		if (msg.type === 'openPanel' && msg.data) {
			clearTimeout(S.timer);
			S.timer = null;
			S.data = msg.data;
			S.draft = null;
			S.dragging = false;
			S.page = 'density';

			applyTheme(msg.data.theme);
			applyBrand(msg.data.brand);
			render();
			el.scrim.classList.add('open');
		} else if (msg.type === 'closePanel') {
			el.scrim.classList.remove('open');
		} else if (msg.type === 'stats') {
			S.stats = msg.data || null;
			paintStats();
		}
	});
})();
