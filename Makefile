version = 1

OS = $(shell uname)

# Thanks to https://stackoverflow.com/a/60413199 and
# Thanks to https://github.com/memkind/memkind/issues/33#issuecomment-540614162
ifeq ($(OS), Darwin)
	MAKEFLAGS := --jobs=$(shell sysctl -n hw.logicalcpu)
else
	MAKEFLAGS := --jobs=$(shell nproc)
endif

# Thanks to https://www.digitalocean.com/community/tutorials/using-ldflags-to-set-version-information-for-go-applications
LD_FLAGS=-s -w -X 'main.BuildDate=$(shell date)'

# Build all binaries
all: freebsd linux macos netbsd openbsd windows

# Clean up old builds/packaging and the Go cache
clean:
	@echo "[Clean] Cleaning up caches and dist/ directories"
	@go clean -cache
	@rm -rf dist/

# Build for FreeBSD
freebsd: clean
	@echo "\033[31m[FreeBSD] Building x86_64 binary\033[0m"
	@env GOOS=freebsd GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-freebsd-amd64-$(version)
	@echo "\033[31m[FreeBSD] Building armv6 binary\033[0m"
	@env GOOS=freebsd GOARM=6 GOARCH=arm go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-freebsd-arm-$(version)
	@echo "\033[31m[FreeBSD] Building arm64 binary\033[0m"
	@env GOOS=freebsd GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-freebsd-arm64-$(version)

# Build for Linux
linux: clean
	@echo "\033[33m[Linux] Building x86_64 binary\033[0m"
	@env GOOS=linux GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-linux-amd64-$(version)
	@echo "\033[33m[Linux] Building armv6 binary\033[0m"
	@env GOOS=linux GOARM=6 GOARCH=arm go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-linux-arm-$(version)
	@echo "\033[33m[Linux] Building arm64 binary\033[0m"
	@env GOOS=linux GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-linux-arm64-$(version)

# Build for macOS
macos: clean
	@echo "\033[36m[macOS/Darwin] Building x86_64 binary\033[0m"
	@env GOOS=darwin GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-darwin-amd64-$(version)
	@echo "\033[36m[macOS/Darwin] Building arm64 binary\033[0m"
	@env GOOS=darwin GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-darwin-arm64-$(version)
	@echo "\033[36m[macOS/Darwin] Building universal binary\033[0m"
	@lipo -create -output dist/aptsched-darwin-universal-$(version) dist/aptsched-darwin-amd64-$(version) dist/aptsched-darwin-arm64-$(version)

# Build for NetBSD
netbsd: clean
	@echo "\033[35m[NetBSD] Building x86_64 binary\033[0m"
	@env GOOS=netbsd GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-netbsd-amd64-$(version)
	@echo "\033[35m[NetBSD] Building armv6 binary\033[0m"
	@env GOOS=netbsd GOARM=6 GOARCH=arm go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-netbsd-arm-$(version)
	@echo "\033[35m[NetBSD] Building arm64 binary\033[0m"
	@env GOOS=netbsd GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-netbsd-arm64-$(version)

# Build for OpenBSD
openbsd: clean
	@echo "\033[32m[OpenBSD] Building x86_64 binary\033[0m"
	@env GOOS=openbsd GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-openbsd-amd64-$(version)
	@echo "\033[32m[OpenBSD] Building armv6 binary\033[0m"
	@env GOOS=openbsd GOARM=6 GOARCH=arm go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-openbsd-arm-$(version)
	@echo "\033[32m[OpenBSD] Building arm64 binary\033[0m"
	@env GOOS=openbsd GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-openbsd-arm64-$(version)

# Build for Windows
windows: clean
	@echo "\033[34m[Windows] Building x86_64 binary\033[0m"
	@env GOOS=windows GOARCH=amd64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-windows-amd64-$(version).exe
	@echo "\033[34m[Windows] Building arm64 binary\033[0m"
	@env GOOS=windows GOARCH=arm64 go build -ldflags="$(LD_FLAGS)" -o dist/aptsched-windows-arm64-$(version).exe

# Build for the platform you are on
me: clean
	@echo ":: Building binary for your platform"
	@go build -ldflags="$(LD_FLAGS)" -o dist/aptsched

# Install the application
install: clean
	@echo "\033[37m:: Building release binary...\033[0m"
	@go build -ldflags="$(LD_FLAGS)" -o dist/aptsched
	@echo "\033[37m:: Installing binary to /usr/local/bin/...\033[0m"
	@sudo mv dist/aptsched /usr/local/bin/
	@echo "\033[31mRemoving dist/ directory...\033[0m"
	@rm -rf dist/

# This is for releases as it builds all the binaries, creates release archives, and a source archive
release: all
	@echo "\n\033[31m[Release: FreeBSD] Making release archive\033[0m"
	@tar -cJf dist/aptsched-freebsd-v$(version).tar.xz dist/aptsched-freebsd-amd64-$(version) dist/aptsched-freebsd-arm64-$(version) dist/aptsched-freebsd-arm-$(version) LICENCE
	@rm -rf dist/aptsched-freebsd-amd64-$(version) dist/aptsched-freebsd-arm64-$(version) dist/aptsched-freebsd-arm-$(version)

	@echo "\033[33m[Release: Linux] Making release archive\033[0m"
	@tar -cJf dist/aptsched-linux-v$(version).tar.xz dist/aptsched-linux-amd64-$(version) dist/aptsched-linux-arm64-$(version) dist/aptsched-linux-arm-$(version) LICENCE
	@rm -rf dist/aptsched-linux-amd64-$(version) dist/aptsched-linux-arm64-$(version) dist/aptsched-linux-arm-$(version)

	@echo "\033[36m[Release: macOS] Making release archive\033[0m"
	@tar -cJf dist/aptsched-macos-v$(version).tar.xz dist/aptsched-darwin-amd64-$(version) dist/aptsched-darwin-arm64-$(version) dist/aptsched-darwin-universal-$(version) LICENCE
	@rm -rf dist/aptsched-darwin-amd64-$(version) dist/aptsched-darwin-arm64-$(version) dist/aptsched-darwin-universal-$(version)

	@echo "\033[35m[Release: NetBSD] Making release archive\033[0m"
	@tar -cJf dist/aptsched-netbsd-v$(version).tar.xz dist/aptsched-netbsd-amd64-$(version) dist/aptsched-netbsd-arm64-$(version) dist/aptsched-netbsd-arm-$(version) LICENCE
	@rm -rf dist/aptsched-netbsd-amd64-$(version) dist/aptsched-netbsd-arm64-$(version) dist/aptsched-netbsd-arm-$(version)

	@echo "\033[32m[Release: OpenBSD] Making release archive\033[0m"
	@tar -cJf dist/aptsched-openbsd-v$(version).tar.xz dist/aptsched-openbsd-amd64-$(version) dist/aptsched-openbsd-arm64-$(version) dist/aptsched-openbsd-arm-$(version) LICENCE
	@rm -rf dist/aptsched-openbsd-amd64-$(version) dist/aptsched-openbsd-arm64-$(version) dist/aptsched-openbsd-arm-$(version)

	@echo "\033[34m[Release: Windows] Making release archive\033[0m"
	@zip -q dist/aptsched-windows-v$(version).zip dist/aptsched-windows-amd64-$(version).exe dist/aptsched-windows-arm64-$(version).exe LICENCE
	@rm -rf dist/aptsched-windows-amd64-$(version).exe dist/aptsched-windows-arm64-$(version).exe

	@$(MAKE) source

# Make a source archive
source:
	@echo "\033[37m[Source] Making archive\033[0m"
	@mkdir -p dist/
	@tar --exclude=dist/ -cJf dist/aptsched-src-v$(version).tar.xz *
