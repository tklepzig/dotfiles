const CACHE_NAME = "docs-cache-2026-01-02";
const baseCache = [
  "/",
  "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs",
  "/github.min.css",
  "/style.css",
  "/sw.js",
  "/theme.js",
  "/manifest.json",
  "/favicon.ico",
];

const docsCache = ["/ai", "/android", "/anti-scam", "/arch-linux", "/asdf", "/bc", "/blender", "/cec", "/chat-gpt", "/colors", "/communication", "/cron", "/cvlc", "/docker", "/engineering-drawing", "/ffmpeg", "/francais", "/fs", "/git", "/github", "/gnome", "/gpg", "/i3", "/ip", "/js-snippets", "/keychron", "/kitty", "/latex", "/Linux", "/luks", "/macos", "/make", "/Manjaro", "/markdown", "/minidlna", "/neovim", "/npm", "/pacman", "/pulseaudio", "/python", "/ranger", "/raspberrypi-os", "/redshift", "/ruby", "/sailing", "/smart", "/ssh", "/systemd", "/tmux", "/vim", "/voice-prep", "/wemux", "/zsh"];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll([...baseCache, ...docsCache]);
    }),
  );
});

self.addEventListener("fetch", function (event) {
  event.respondWith(
    caches.match(event.request).then(function (response) {
      if (response) {
        return response;
      }

      return fetch(event.request).then(function (response) {
        if (
          !response ||
          response.status !== 200 ||
          (response.type !== "basic" && response.type !== "cors")
        ) {
          return response;
        }

        // Do not cache newly created requests which are not listed above
        //var responseToCache = response.clone();
        //caches.open(CACHE_NAME).then(function(cache) {
        //cache.put(event.request, responseToCache);
        //});

        return response;
      });
    }),
  );
});
