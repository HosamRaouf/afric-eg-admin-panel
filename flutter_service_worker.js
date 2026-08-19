'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "5b5e4a10ac81c3a6e22c5cc68372723b",
"version.json": "5ba9090dbea1a5ff5a3a181b82dfb530",
"index.html": "ea7d0c05a4ee5afc5d391598b576f40c",
"/": "ea7d0c05a4ee5afc5d391598b576f40c",
"main.dart.js": "c16d62398e0dbc8bd8b5164bfd061c86",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "c0c0b68d44fff5e4eed965b0670eafff",
"icons/Icon-192.png": "ae1f765f04bf4d6051ac4c2b490f4553",
"icons/Icon-maskable-192.png": "45d21ab8fce90b5e2b44b015278ea30b",
"icons/Icon-maskable-512.png": "76837714fc5c52d93cad011e287a92d7",
"icons/Icon-512.png": "db0c43c37e662cb132c88d1add6a8061",
"manifest.json": "5f3737ccdb0ea33133b8c232c88c93ca",
".git/config": "38881ccff4dc4e249623736f3cd97a15",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "50f3380c9772e107150d87533c44f28d",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "27692dea2feef734dbb4475191d0b203",
".git/objects/04/7c92f6e2212473dc436020afed689527076d44": "2b596496a0fca3b4663669512835bd77",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "80c87d02687031734a2db0a24528870c",
".git/objects/51/3863f8c836038a552ec326e4cc0bbb749fa2fb": "a618037e4e4f7e0ad575410456564a78",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "70d096a1769c7715b67dc1b780a35781",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c5c14c6ba3bb02da4e5392d205ee6267",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "ae4ee21bd71069c6e962deed7485df4f",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "572f37892d3ef53b60b273b30f6436e4",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "1a4ee0c85a695a5f8ce1f75dac7efc0c",
".git/objects/be/1f6497b72aaae28e926e9737ace549af2d6a62": "17ffeaacce579f41b7a5edecaf0a9a43",
".git/objects/da/eff433d2356edbbb146c09554c0a83722d7a4d": "55517c49ec399b6031b413a258e85e69",
".git/objects/b4/08630946e02ffe5072d3df4eae4a495ab58697": "34bdf9a7f8b29c3d9665fd317cf98241",
".git/objects/d1/dc1e85f3045bc942d6d1aa5d3497e5e1c301a5": "4f8a177120bf4860d93ef6e79bcb674d",
".git/objects/e2/65244416e7516cd25d90aa97ba95c710c0ad70": "1d6bd68f7c4765bc48147735ab715120",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "cb1ad23398d21b0518b0805134ac5acc",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "d534e39531c224a748c356a964b910b0",
".git/objects/fd/463ddd60b70453391b6782d391ea7ecb2fa8fc": "99ecde5d2e0bd64768caa67b60c62b81",
".git/objects/f2/ff95a66ce1ed40fd313f5a72980b4cedfa7135": "5dad81ff69c4e7041b32a08280b6f845",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "fb2ee964a7fc17b8cba79171cb799fa3",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "4938f34d9cc8dae979506ac87d0a571f",
".git/objects/29/55a9bb4b40fb8301c5bd20bd08b4634d0765fa": "b8b21ef675fd9dfe17b229f14078a50a",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "85fb081f640fd858e1baa68db8f3e55d",
".git/objects/19/8c63f8ab6b8337761444578af498a65489b7f6": "f991b9273d87ee58e8d7797643de6b58",
".git/objects/4d/0563fd9830ed7bebc94b4d7d933a8b6abd98df": "6335cd31b545612f5303c10f9ae1605c",
".git/objects/44/f722bf5bbdac3eb38a9471a565972de31adf0a": "707d3046eee4e697b6fad91db0d3bf16",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "9524d053d0586a5f9416552b0602a196",
".git/objects/9a/25fbabbee348f2f4d0fd8995cee32cb2eb0a99": "7318a96989c26860b615258a51b2c5be",
".git/objects/9a/18ee525ec945b145438cafd60e74f6784eb3e6": "39503b4a3e0f448d725d90400a07d8d1",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "b92a0f6b7400ff035ef092a8709952e1",
".git/objects/3a/db08b9e77614b860307e0c026c0a7eb76e56b3": "5b69f38262e660487ebe5b63bfb4699e",
".git/objects/30/71f071c277427cc83b2dfecf0d21be87467e0d": "a975bc23e6a820d54c7ed5097c627449",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "a2c957fcd2f5f0e686f9a496d6e3a59d",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "9dbf5b01e391c548c8343be8d1d4b04e",
".git/objects/dd/42bd744a9fccc61770e47280bbda2b0601c1ed": "4d0ded2735f43cdeed7534d0a5f36897",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "96233f83e8615fc3bc2c252e4aaa5698",
".git/objects/a1/b2e6c26093066510a31147e7aec9abdc8d6c5e": "4fda652a23db24ce782824b151e509dc",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "e223dd636229c40679173e18c0a3e275",
".git/objects/ff/ba8c99021f5634acf09d3720fd5d1ae8c0d9df": "51c5c7c73c6fecdda39117d8de313df8",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "badc782b67bf359bcce68100f8fe4312",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "c3694958e54483a81b3e32ab9f84ece2",
".git/objects/46/3582e134c207e2ead09cb2ebc024e9fb93c3ef": "6056edcce488a636d7ef9dd66ce2784b",
".git/objects/77/64411daea617d2bbc149b723e9337fecfe4f67": "7234c615ae6feee6f75ae8042e3b11ad",
".git/objects/8c/d29c974c92d3c164442ce6770d0a01e9d844a6": "c10fbbc38f52dbcb6c44ad0599e683d3",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "bb5ad116423ddf07049c2730cdb0c772",
".git/objects/1c/794fc4a68fb94d1f00f7134eaa5d79d9b669de": "91afe69ecfc55eef612e1126b1a8fdf1",
".git/objects/7f/2dec6768aa7c7a881ee5b86c219566239bd3a8": "72b3c34f46dd8e0d4ec8ca7de3786030",
".git/objects/14/f62bcf0201ff52057244aa601437b78f409503": "cd44c88c410dfd43d2bb80d3c47977b5",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "7a4f4ebfe14f2be524ecae012e7e2a2d",
".git/logs/refs/heads/main": "7a4f4ebfe14f2be524ecae012e7e2a2d",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "367384e9d532974d64c1fa8b4b96a219",
".git/index": "c7cc834029581c8782574c8ee517d70a",
".git/COMMIT_EDITMSG": "3cb05c7d26ca4c52db0bca6cd9258308",
"assets/NOTICES": "c15015d969d6dcd39292148bae6e40c4",
"assets/FontManifest.json": "b42f89f21d55b6d040308150935a6980",
"assets/AssetManifest.bin.json": "bebae7ff757af545a54d0ca9a9210afc",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "ade09d9916d0151cfd2d9ace9bb356ce",
"assets/fonts/MaterialIcons-Regular.otf": "0ea69f038c803538279c1f6d84cfda22",
"assets/assets/fonts/Inter-Variable.ttf": "bff0f6e3b9e2259a28313168a907054f",
"assets/assets/fonts/SpaceGrotesk-Variable.ttf": "effdd4f91ca207acce255f127a81d842",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
