/* Apple Music True Shuffle — deployed by firephlox as a native WebExtension.
 * No data collection. No telemetry. No userscript manager required. */
(function () {
    'use strict';

    const TAG = '[firephlox shuffle]';

    /* Durstenfeld / Fisher-Yates in-place shuffle — statistically unbiased. */
    function trueShuffle(arr) {
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    }

    /*
     * Selector strategy (from live DOM inspection):
     *  1. [data-testid="player-bar"] .action-buttons  — right-side actions row
     *     (holds lyrics / up-next / volume, open flex space, stable data-testid)
     *  2. [data-testid="playback-controls"]            — centre controls row
     *  3. Fixed floating pill as absolute last resort
     */
    function findContainer() {
        const bar = document.querySelector('[data-testid="player-bar"]');
        if (!bar) return null;
        return bar.querySelector('.action-buttons')
            || document.querySelector('[data-testid="playback-controls"]');
    }

    /* Returns a fixed floating container when no player bar is found yet. */
    function getOrCreateFloater() {
        let f = document.getElementById('fp-shuffle-floater');
        if (!f) {
            f = document.createElement('div');
            f.id = 'fp-shuffle-floater';
            f.style.cssText = 'position:fixed;bottom:16px;right:80px;z-index:99999';
            document.body.appendChild(f);
            console.log(TAG, 'player bar not found — using fixed floater');
        }
        return f;
    }

    function injectButton() {
        if (document.getElementById('fp-true-shuffle-btn')) return;

        const container = findContainer() || getOrCreateFloater();

        const btn       = document.createElement('button');
        btn.id          = 'fp-true-shuffle-btn';
        btn.textContent = '🎲 True Shuffle';
        btn.style.cssText = [
            'background-color:#fa243c',
            'color:#fff',
            'border:none',
            'border-radius:20px',
            'padding:5px 12px',
            'font-size:11px',
            'font-weight:bold',
            'cursor:pointer',
            'margin-left:8px',
            'white-space:nowrap',
            'flex-shrink:0',
            'transition:background 0.2s ease',
        ].join(';');

        btn.addEventListener('mouseenter', () => { btn.style.backgroundColor = '#d11b30'; });
        btn.addEventListener('mouseleave', () => { btn.style.backgroundColor = '#fa243c'; });

        btn.addEventListener('click', async () => {
            const mk = window.MusicKit?.getInstance();
            if (!mk) {
                alert('MusicKit not ready — wait for the page to fully load.');
                return;
            }

            const queue = mk.queue;
            if (!queue || queue.items.length <= 1) {
                alert('Not enough songs in the queue to shuffle.');
                return;
            }

            const orig = btn.textContent;
            btn.textContent = '🔄 Shuffling…';
            btn.disabled    = true;

            try {
                const shuffled = trueShuffle([...queue.items]);
                await queue.clear();
                await queue.append(shuffled);
                await mk.play();
                btn.textContent = '✅ Shuffled!';
            } catch (err) {
                console.error(TAG, 'error:', err);
                btn.textContent = '❌ Error';
            } finally {
                setTimeout(() => {
                    btn.textContent = orig;
                    btn.disabled    = false;
                }, 2000);
            }
        });

        container.appendChild(btn);
        console.log(TAG, 'button injected into', container.dataset.testid || container.className);
    }

    console.log(TAG, 'content script loaded on', location.href);
    new MutationObserver(injectButton)
        .observe(document.body, { childList: true, subtree: true });
    injectButton();
})();

