# cache manager

Vala cache library with a shared cache API and multiple storage backends.

## Contents

- [Overview](#overview)
- [Implemented Backends](#implemented-backends)
- [Core API](#core-api)
- [Quick Usage](#quick-usage)
- [Build](#build)
- [Test](#test)
- [Release artifacts](#release-artifacts)
- [Use generated library in other projects](#use-generated-library-in-other-projects)
- [Install via Vamposer](#install-via-vamposer)
- [Dependencies](#dependencies)
- [License](#license)


## Overview

This project provides:

- common cache interface (`CacheInterface`)
- common cache item interface (`CacheItemInterface`)
- in-memory backend
- filesystem backend with persisted items

TTL constants are available in the `ValaFoundation.CacheManager` namespace:

- `DEFAULT_TTL`
- `TTL_MINUTE`, `TTL_HOUR`, `TTL_DAY`, `TTL_WEEK`, `TTL_MONTH`, `TTL_YEAR`
- `TTL_INFINITE`


## Implemented Backends

### Memory backend

Namespace: `ValaFoundation.CacheManager.Memory`

- stores items in RAM
- no serialization required
- supports `save`, `getItem`, `getItems`, `hasItem`, delete operations, and `clear`

### Filesystem backend

Namespace: `ValaFoundation.CacheManager.Filesystem`

- stores items as `.cache` files in a cache directory
- uses hashed key names for file paths
- supports persistence across process restarts
- supports JSON payloads via `GLib.Value` with `Json.Node`

Supported filesystem value types:

- `string`
- `int`, `int64`
- `uint`, `uint64`
- `bool`
- `double`
- `Json.Node`


## Core API

Cache:

- `CacheItemInterface? getItem (string key)`
- `CacheItemInterface[] getItems (string[] keys)`
- `bool hasItem (string key)`
- `bool clear ()`
- `bool deleteItem (string key)`
- `bool deleteItems (string[] keys)`
- `bool save (CacheItemInterface item)`
- `bool saveItems (CacheItemInterface[] items)`
- `bool saveDeferred (CacheItemInterface item)`
- `bool commit ()`

Cache item:

- `string getKey ()`
- `Value? getValue ()`
- `bool IsHit ()`
- `CacheItemInterface setValue (Value? value, int ttl = 0)`
- `CacheItemInterface expireAfter (int ttl)`
- `CacheItemInterface expireAt (int timestamp)`


## Quick Usage

### Memory cache

```vala
using GLib;
using ValaFoundation.CacheManager;

var cache = new ValaFoundation.CacheManager.Memory.Cache ();
var item = new ValaFoundation.CacheManager.Memory.CacheItem ("user:1");

Value value = Value (typeof (string));
value.set_string ("alice");

item.setValue (value, (int) TTL_MINUTE);
cache.save (item);

CacheItemInterface? loaded = cache.getItem ("user:1");
if (loaded != null && loaded.IsHit ()) {
	Value? loaded_value = loaded.getValue ();
	stdout.printf ("%s\n", loaded_value.get_string ());
}
```

### Filesystem cache with JSON value

```vala
using GLib;
using Json;
using ValaFoundation.CacheManager;

var cache = new ValaFoundation.CacheManager.Filesystem.Cache ();
var item = new ValaFoundation.CacheManager.Filesystem.CacheItem ("profile");

var parser = new Json.Parser ();
parser.load_from_data ("{\"name\":\"alice\",\"age\":30}", -1);

Value value = Value (typeof (Json.Node));
value.set_boxed (parser.get_root ().copy ());

item.setValue (value, (int) TTL_HOUR);
cache.save (item);
```


## Build

```sh
meson setup builddir
meson compile -C builddir
```

## Test

```sh
meson test -C builddir
```

or via Makefile helper:

```sh
make tests
```

## Release artifacts

Tag-based release workflow (`v*`) publishes:

- shared library (`lib*.so*`)
- generated VAPI (`src/vapi/*.vapi`)
- generated header (`src/*.h`)
- bundled ZIP (`<repo-name>-<tag>-linux.zip`)

## Use generated library in other projects

### Option 1: Meson subproject dependency

In consumer project root:

```sh
./init.sh
```

Or run directly from GitHub:

```sh
curl -sSfL https://raw.githubusercontent.com/ValaFoundation/cache-manager/master/init.sh -o init.sh && chmod +x init.sh && ./init.sh && rm init.sh
```

### Option 2: Local vapi/lib/include integration

In consumer project root:

```sh
curl -sSfL https://raw.githubusercontent.com/ValaFoundation/cache-manager/master/init-local-vapi.sh | bash
```

This helper downloads release artifacts (or builds from source) and prepares local `vapi/`, `lib/`, and `include/` folders plus reusable Meson variables.

## Install via [Vamposer](https://github.com/ValaFoundation/vamposer)

In your consumer project root:

```sh
vamposer require ValaFoundation/cache-manager master
vamposer install
```

Then include generated Vamposer dependencies in your `meson.build`:

```meson
subdir('vamposer')

executable('my-app',
	sources,
	dependencies: [
		vamposer_deps
	]
)
```

You can also use a fixed tag or commit instead of `master`.

## Dependencies

- glib-2.0
- gio-2.0
- gee-0.8
- json-glib-1.0
- vala_testcases (tests only)

## License

MIT (see `LICENSE`).
