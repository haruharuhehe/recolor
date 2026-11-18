# recolor - build aovnet menu recolour dylib

No Mac needed. Pick one route.

## A. GitHub Actions (easiest, free)

`recolor/` must be the repo root (so `.github/workflows/build.yml` sits at
`.github/workflows/build.yml`).

```bash
cd "D:/Du lieu/Pictures/crack/recolor"
git init
git add .
git commit -m "recolor tweak"
gh repo create recolor --private --source . --push     # or push to an existing repo
```

Then: repo -> Actions -> "build tweak" -> wait ~3 min -> download the
`recolor` artifact. It contains:

* `packages/com.olltaterfx.recolor_1.0_iphoneos-arm.deb` - install with Sileo /
  Filza / Zebra, requires a jailbroken device with substrate.
* `.theos/obj/recolor.dylib` - the bare dylib, for IPA injection (Esign,
  TrollStore, Sideloadly) when there is no substrate.

## B. Local build in WSL or Docker

Ubuntu/Debian, one shot:

```bash
sudo apt-get update
sudo apt-get install -y make git curl file unzip xz-utils fakeroot libxml2-utils
echo "y" | bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
export THEOS="$HOME/theos"
cd recolor && make package FINALPACKAGE=1
```

Docker instead, if you prefer not to touch the host:

```bash
docker run -it --rm -v "$PWD":/work -w /work debian:latest bash
```

then the same four package commands plus the theos install line.

## C. On the phone itself

If NewTerm has theos (`apt install theos clang make ldid git`), you can build
straight on the device:

```bash
cd /var/mobile/recolor
make package FINALPACKAGE=1
```

Untested for this project; the toolchain on device is often incomplete, so
route A is safer.

## Installing the result

Jailbroken + substrate:

```bash
dpkg -i packages/com.olltaterfx.recolor_1.0_iphoneos-arm.deb
killall -9 ArenaOfValor
```

No substrate (inject into the IPA instead):

1. take the game .ipa, unzip
2. copy `recolor.dylib` into `Payload/<App>.app/Frameworks/`
3. add LC_LOAD_DYLIB `@executable_path/Frameworks/recolor.dylib` with your
   injector (Esign "inject dylib", TrollStore, azule, etc.)
4. re-sign and install
5. keep `aovnet` untouched - it must be the ORIGINAL, not `aovnet_red`

Check with Console.app / `idevicesyslog`:

```
[recolor] armed
[recolor] ImGuiCol table @ 0x...
[recolor] crimson applied: 62/62 slots over 1 table(s)
```

If you only ever see `armed` and never a table, the scan window was too short -
the game probably loaded its menu later. Change `gTicks <= 40` to a larger
number in `Tweak.xm`.

## If the build fails

`ARCHS = arm64 arm64e` needs a recent clang. If the arm64e slice is rejected,
drop `arm64e` in the Makefile - arm64 alone loads fine on arm64e devices.
