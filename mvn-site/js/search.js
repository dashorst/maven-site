// Search as you type. Without this script every search form opens search.html, which lists every
// page of the site; with it the form answers from search.json while you type. search.json is
// written after site:site by org.apache.maven.site.render.SearchIndex.
//
// The index holds a record per page and per section, so a result can open the section that
// answers the question. Guide pages rank above the other pages of the site. Element and option
// names are indexed whole and split at their parts, so "mirrorof" and "mirror of" both find
// <mirrorOf>.
(function () {
    var KINDS = { tutorial: 'Tutorial', howto: 'How-to', reference: 'Reference', explanation: 'Explanation', page: '' };
    var MAX = 10;

    // Splits names at their capitals and punctuation: <mirrorOf> also yields mirror, of.
    function tokenize(text) {
        var out = [];
        text.split(/[^A-Za-z0-9_.-]+/).forEach(function (w) {
            w = w.replace(/^[.-]+|[.-]+$/g, '');
            if (!w) return;
            out.push(w);
            var parts = w.split(/[._-]+|(?=[A-Z][a-z])|(?<=[a-z0-9])(?=[A-Z])/).filter(Boolean);
            if (parts.length > 1) out.push.apply(out, parts);
        });
        return out;
    }

    var STOP = {};
    ('a an and are as at be by can do does for from get how i if in into is it its my of on or ' +
     'should so that the their then there this to use using want was what when where which why ' +
     'will with without you your').split(' ').forEach(function (w) { STOP[w] = true; });

    function processTerm(term) {
        var t = term.toLowerCase();
        return STOP[t] ? null : t;
    }

    var loading = null;
    function engine(form) {
        if (loading) return loading;
        loading = new Promise(function (resolve, reject) {
            if (window.MiniSearch) return resolve();
            var script = document.createElement('script');
            script.src = form.getAttribute('data-script');
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        }).then(function () {
            return fetch(form.getAttribute('data-index'));
        }).then(function (response) {
            return response.json();
        }).then(function (records) {
            // URLs in the index are relative to the site's root, where search.json is.
            var root = new URL(form.getAttribute('data-index'), window.location.href);
            records.forEach(function (r) { r.url = new URL(r.url, root).href; });
            var search = new window.MiniSearch({
                fields: ['title', 'terms', 'keywords', 'page', 'text', 'body'],
                storeFields: ['url', 'title', 'page', 'kind', 'topic', 'text'],
                tokenize: tokenize,
                processTerm: processTerm,
                searchOptions: {
                    processTerm: processTerm,
                    boost: { title: 4, terms: 3, keywords: 2, page: 1.5, text: 1, body: 0.5 },
                    // Guide pages answer a question better than the pages they were written from.
                    boostDocument: function (id, term, stored) { return stored && stored.kind === 'page' ? 0.4 : 1; },
                    prefix: function (term, i, terms) { return i === terms.length - 1 && term.length > 2; },
                    fuzzy: function (term) { return term.length > 4 ? 0.2 : false; },
                    tokenize: function (q) { return tokenize(q); }
                }
            });
            search.addAll(records);
            return search;
        });
        loading.catch(function () { loading = null; });
        return loading;
    }

    function run(search, query) {
        var results = search.search(query, { combineWith: 'AND' });
        if (!results.length) results = search.search(query);
        // At most three results per page, so one long page does not fill the list.
        var perPage = {};
        return results.filter(function (r) {
            var page = r.url.split('#')[0];
            perPage[page] = (perPage[page] || 0) + 1;
            return perPage[page] <= 3;
        }).slice(0, MAX);
    }

    var count = 0;
    function setup(form) {
        var input = form.querySelector('input[type=search]');
        var id = 'search-results-' + (++count);
        var panel = document.createElement('div');
        panel.className = 'search-results';
        panel.hidden = true;
        var list = document.createElement('ul');
        list.id = id;
        list.setAttribute('role', 'listbox');
        list.setAttribute('aria-label', 'Search results');
        var empty = document.createElement('p');
        empty.className = 'search-empty';
        empty.hidden = true;
        var status = document.createElement('p');
        status.className = 'visually-hidden';
        status.setAttribute('role', 'status');
        panel.appendChild(list);
        panel.appendChild(empty);
        form.querySelector('.search-field').appendChild(panel);
        form.appendChild(status);

        input.setAttribute('role', 'combobox');
        input.setAttribute('aria-autocomplete', 'list');
        input.setAttribute('aria-expanded', 'false');
        input.setAttribute('aria-controls', id);

        var active = -1;
        var items = [];

        function close() {
            panel.hidden = true;
            input.setAttribute('aria-expanded', 'false');
            input.removeAttribute('aria-activedescendant');
            active = -1;
        }

        function select(i) {
            if (items[active]) items[active].classList.remove('is-active');
            active = i;
            if (items[i]) {
                items[i].classList.add('is-active');
                input.setAttribute('aria-activedescendant', items[i].id);
                items[i].scrollIntoView({ block: 'nearest' });
            }
        }

        function span(cls, text) {
            var s = document.createElement('span');
            s.className = cls;
            s.textContent = text;
            return s;
        }

        function render(results, query) {
            list.textContent = '';
            items = [];
            active = -1;
            results.forEach(function (r, i) {
                var li = document.createElement('li');
                li.id = id + '-' + i;
                li.setAttribute('role', 'option');
                var a = document.createElement('a');
                a.href = r.url;
                a.tabIndex = -1;
                a.appendChild(span('result-title', r.title));
                var meta = document.createElement('span');
                meta.className = 'result-meta';
                var where = r.title === r.page ? [KINDS[r.kind], r.topic] : ['In ' + r.page, KINDS[r.kind]];
                where.filter(Boolean).forEach(function (part) { meta.appendChild(span('', part)); });
                a.appendChild(meta);
                if (r.text) a.appendChild(span('result-text', r.text));
                li.appendChild(a);
                li.addEventListener('mousedown', function (e) { e.preventDefault(); });
                li.addEventListener('click', function () { window.location.href = r.url; });
                list.appendChild(li);
                items.push(li);
            });
            empty.hidden = results.length > 0;
            empty.textContent = 'Nothing matches “' + query + '”. Try an element, an option or fewer words.';
            status.textContent = results.length ? results.length + ' results' : 'No results';
            panel.hidden = false;
            input.setAttribute('aria-expanded', 'true');
        }

        var pending = 0;
        function update() {
            var query = input.value.trim();
            if (query.length < 2) { close(); return; }
            var ticket = ++pending;
            engine(form).then(function (search) {
                if (ticket !== pending) return;
                render(run(search, query), query);
            }, function () {
                // Leave the form to do its plain job: open the page that lists every page.
                close();
            });
        }

        input.addEventListener('focus', function () { engine(form); if (input.value.trim().length > 1) update(); });
        input.addEventListener('input', update);
        input.addEventListener('blur', function () { setTimeout(close, 100); });
        input.addEventListener('keydown', function (e) {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (panel.hidden) update(); else select(Math.min(active + 1, items.length - 1));
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                select(Math.max(active - 1, 0));
            } else if (e.key === 'Escape') {
                if (!panel.hidden) { e.preventDefault(); close(); } else { input.value = ''; }
            }
        });
        form.addEventListener('submit', function (e) {
            var item = items[active] || items[0];
            if (item && !panel.hidden) {
                e.preventDefault();
                window.location.href = item.querySelector('a').href;
            }
        });

        var q = new URLSearchParams(window.location.search).get('q');
        if (q && !input.value) {
            input.value = q;
            if (form.classList.contains('search--large')) { input.focus(); update(); }
        }
    }

    Array.prototype.forEach.call(document.querySelectorAll('form.search'), setup);

    // "/" jumps to the search: the large one on the search page, otherwise the header's.
    document.addEventListener('keydown', function (e) {
        if (e.key !== '/' || e.ctrlKey || e.metaKey || e.altKey) return;
        var t = e.target;
        if (t && (t.isContentEditable || /^(input|textarea|select)$/i.test(t.tagName))) return;
        var input = document.querySelector('.search--large input') || document.querySelector('form.search input');
        if (!input) return;
        e.preventDefault();
        input.focus();
        input.select();
    });
})();
