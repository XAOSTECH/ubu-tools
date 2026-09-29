/* Apple Music True Shuffle — deployed by firephlox as a native WebExtension.
 * No data collection. No telemetry. No userscript manager required. */
(function () {
    'use strict';

    /* Durstenfeld / Fisher-Yates in-place shuffle — statistically unbiased. */
    function trueShuffle(arr) {
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    }

    function injectButton() {
        const bar = document.querySelector('.web-chrome-controls-container')
                 || document.querySelector('.playback-controls');
        if (!bar || document.getElementById('fp-true-shuffle-btn')) return;

        const btn       = document.createElement('button');
        btn.id          = 'fp-true-shuffle-btn';
        btn.textContent = '🎲 True Shuffle';
        btn.style.cssText = [
            'background-color:#fa243c',
            'color:#fff',
            'border:none',
            'border-radius:20px',
            'padding:6px 14px',
            'font-size:12px',
            'font-weight:bold',
            'cursor:pointer',
            'margin-left:10px',
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
                console.error('[firephlox] true-shuffle error:', err);
                btn.textContent = '❌ Error';
            } finally {
                setTimeout(() => {
                    btn.textContent = orig;
                    btn.disabled    = false;
                }, 2000);
            }
        });

        bar.appendChild(btn);
    }

    new MutationObserver(injectButton)
        .observe(document.body, { childList: true, subtree: true });
    injectButton();
})();
