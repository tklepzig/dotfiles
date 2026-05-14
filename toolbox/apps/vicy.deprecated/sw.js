var CACHE_NAME = "vicy-cache-2019-02-17_2";
var urlsToCache = [
  "/",
  "/manifest.json",
  "/favicon.ico",
  "/sw.js",
  "/vigenere.js",
  "/style.min.css",
  "/assets/logo-192.png",
  "/assets/logo-512.png",
  "https://fonts.googleapis.com/css?family=Open+Sans",
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll(urlsToCache);
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
