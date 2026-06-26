const CACHE_NAME = "docs-cache-2026-06-26f";
const baseCache = [
  "/",
  "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs",
  "/github.min.css",
  "/style.css",
  "/sw.js",
  "/theme.js",
  "/manifest.json",
  "/favicon.ico",
  "/favicon.svg",
  "/favicon-32.png",
  "/apple-touch-icon.png",
];

const docsCache = [];

self.addEventListener("install", function (event) {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll([...baseCache, ...docsCache]);
    }),
  );
});

// Drop stale caches so a new icon/asset isn't pinned by an old cache name, then
// take control of open clients immediately (matches the install skipWaiting).
self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches
      .keys()
      .then(function (cacheNames) {
        return Promise.all(
          cacheNames
            .filter(function (cacheName) {
              return cacheName !== CACHE_NAME;
            })
            .map(function (cacheName) {
              return caches.delete(cacheName);
            }),
        );
      })
      .then(function () {
        return self.clients.claim();
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
