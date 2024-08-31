# liskvork

Linux native piskvork reimplementation.

It should also support Mac (Intel and Apple Silicon) and Windows but if there
are problems please open an issue
[here](https://github.com/Epitech/B-AIA-500_liskvork/issues). Those other
platforms are not a priority but I while give support for them.

## Building from source

### Docker

```sh
VERSION=1.0.0 docker build . --build-arg BUILD_VERSION=${VERSION} -t liskvork:${VERSION}
```

### No docker

#### Dependencies

- zig 0.13.0 (May work with older or newer versions but has not been tested)

#### Step

```sh
zig build -Doptimize=ReleaseSafe
```

## Installing

TBD

## Launching liskvork

### System package

Just launch liskvork like this:

```sh
liskvork
```

### From source build

```sh
# From the root of the repository once built
./zig-out/bin/liskvork
```

### Docker

```sh
# Once compiled with docker
VERSION=1.0.0 docker run liskvork:${VERSION}
```

## Configuration

TBD
