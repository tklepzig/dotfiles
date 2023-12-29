const CACHE_NAME = "docs-cache-2023-12-28";
const baseCache = [
  "/",
  "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs",
  "/github.min.css",
  "/style.css",
  "/sw.js",
];

const docsCache = [];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll([...baseCache, ...docsCache]);
    })
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
    })
  );
});
