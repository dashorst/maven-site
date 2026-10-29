// Optional additions to a page; without this script nothing is missing that the reader needs.
//  - an anchor link on every h2 and h3 of the text,
//  - "On this page" in the rail, from the h2s (and the h3s when there are two h2s or fewer),
//  - on the search page, the list of every page filtered while you type,
//  - on a page that has moved, straight on to the new place of the section the address points at.
(function () {
    var prose = document.querySelector('.prose');
    if (!prose) return;

    var moved = prose.querySelector('.moved');
    if (moved) {
        var target = location.hash && document.getElementById(decodeURIComponent(location.hash.slice(1)));
        var item = target && target.closest('li, p');
        var link = (item && item.querySelector('a[href]')) || moved.querySelector('p a[href]');
        if (link) {
            location.replace(link.href);
            return;
        }
    }

    function idOf(h) {
        if (h.id) return h.id;
        var a = h.querySelector('a[id], a[name]') || (h.previousElementSibling && h.previousElementSibling.matches('a[id], a[name]') ? h.previousElementSibling : null);
        var section = h.parentElement && h.parentElement.tagName === 'SECTION' && h.parentElement.firstElementChild === h ? h.parentElement : null;
        var id = (a && (a.id || a.name)) || (section && section.id) ||
            h.textContent.trim().replace(/[^A-Za-z0-9]+/g, '_').replace(/^_|_$/g, '');
        if (!document.getElementById(id)) h.id = id;
        return id;
    }

    var heads = Array.prototype.filter.call(prose.querySelectorAll('h2, h3'), function (h) {
        return !h.closest('nav, aside, .facts');
    });
    heads.forEach(function (h) {
        var a = document.createElement('a');
        a.className = 'anchor';
        a.href = '#' + idOf(h);
        a.setAttribute('aria-label', 'Link to this section');
        a.innerHTML = '<svg aria-hidden="true" viewBox="0 0 16 16" width="14" height="14"><path d="M6.5 9.5l3-3M7 4.5l1-1a2.5 2.5 0 013.5 3.5l-1 1M9 11.5l-1 1A2.5 2.5 0 014.5 9l1-1" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>';
        h.appendChild(a);
    });

    var toc = document.getElementById('on-this-page');
    var h2s = heads.filter(function (h) { return h.tagName === 'H2'; });
    var listed = h2s.length > 2 ? h2s : heads;
    if (toc && listed.length > 1) {
        var html = '<h2>On this page</h2><ul>';
        listed.forEach(function (h) {
            var text = h.cloneNode(true);
            text.querySelectorAll('.anchor').forEach(function (a) { a.remove(); });
            html += '<li' + (h.tagName === 'H3' ? ' class="sub"' : '') + '><a href="#' + h.id + '">' +
                text.textContent.trim().replace(/[&<>]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]; }) + '</a></li>';
        });
        toc.innerHTML = html + '</ul>';
    }

    // The search page lists every page; the query filters that list.
    var all = /\/search\.html$/.test(location.pathname) ? prose : null;
    var input = document.getElementById('q');
    if (all && input) {
        var q = new URLSearchParams(location.search).get('q') || '';
        input.value = q;
        var filter = function () {
            var words = input.value.toLowerCase().split(/\s+/).filter(Boolean);
            all.querySelectorAll('li').forEach(function (li) {
                var text = li.textContent.toLowerCase();
                li.hidden = !words.every(function (w) { return text.indexOf(w) >= 0; });
            });
            all.querySelectorAll('section').forEach(function (box) {
                box.hidden = !box.querySelector('li:not([hidden])');
            });
        };
        input.addEventListener('input', filter);
        filter();
    }
})();
