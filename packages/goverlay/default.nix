# goverlay "latest" package, tracked intentionally in this repo (exported as
# goverlay_latest). Kept at the newest upstream release, currently 1.9.4; bump
# together with upstream releases (nix-update-script available via passthru).
# Based on the nixpkgs expression for 1.9.2 plus the 1.9.3+ build changes:
# bgmod-splash project, bgmod binaries before checkPhase, two sandbox-failing
# logic tests skipped (same as the Gentoo ebuild for 1.9.4).
{
  bash,
  coreutils,
  curl,
  fetchFromGitHub,
  fpc,
  git,
  glib,
  gnugrep,
  gnused,
  iproute2,
  kmod,
  lazarus-qt6,
  lib,
  libnotify,
  libx11,
  libz,
  mangohud,
  nix-update-script,
  p7zip,
  patchelfUnstable,
  pciutils,
  polkit,
  procps,
  psmisc,
  qt6Packages,
  SDL2,
  stdenv,
  which,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "goverlay";
  version = "1.9.4";

  src = fetchFromGitHub {
    owner = "benjamimgois";
    repo = "goverlay";
    tag = finalAttrs.version;
    hash = "sha256-HAQd/Fb0eejvyn/XthX4d6wb1ip2TvoHtmTo0eFwoY0=";
  };

  outputs = [
    "out"
    "man"
  ];

  postPatch = ''
    substituteInPlace data/goverlay.sh.in --replace-fail 'mangohud' "${lib.getExe mangohud}"

    # Skip two bgmod supervisor integration tests that spawn the real splash
    # process / emulate the Steam Linux Runtime entrypoint and fail in the
    # sandboxed Nix build (verified empirically on 1.9.4; the Gentoo ebuild
    # for 1.9.4 skips the same tests). All other logic tests still run.
    substituteInPlace tests/logic/logic_test_cases.pas \
      --replace-fail "  TestGameDir := IsolatedHome + '/.local/share/goverlay/gameconfig/Control Ultimate Edition';" \
        "  Exit; // nix: sandboxed-build skip (async launch splash)" \
      --replace-fail "  TestGameDir := IsolatedHome + '/.local/share/goverlay/gameconfig/EuroTruckNativeTest';" \
        "  Exit; // nix: sandboxed-build skip (native binary resolution)"
  '';

  nativeBuildInputs = [
    fpc
    lazarus-qt6
    patchelfUnstable
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.libqtpas
    qt6Packages.qtbase
    SDL2
  ];

  installFlags = [ "prefix=$(out)" ];

  buildPhase = ''
    runHook preBuild
    # goverlay
    HOME=$(mktemp -d) lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B goverlay.lpi --bm=Release
    # pascube_bin
    HOME=$(mktemp -d) lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B pascube_src/pascube.lpi
    cp pascube_src/pascube pascube
    # bgmod-splash (new in 1.9.3). Built here so `make install` finds the target
    # up to date and never invokes bare lazbuild without --lazarusdir.
    HOME=$(mktemp -d) lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B bgmod_splash_src/bgmod_splash.lpi --ws=qt6
    cp bgmod_splash_src/bgmod-splash bgmod-splash
    mkdir -p data/bgmod
    cp bgmod-splash data/bgmod/bgmod-splash
    # bgmod / bgmod-uninstaller: the 1.9.4 logic tests exec the real bgmod binary
    # (mirrors upstream `test-logic: bgmod bgmod-uninstaller bgmod-splash`),
    # so they must exist before checkPhase.
    fpc -O3 bgmod.lpr
    cp bgmod data/bgmod/bgmod
    cp bgmod.conf data/bgmod/bgmod.conf
    fpc -O3 bgmod-uninstaller.lpr
    cp bgmod-uninstaller data/bgmod/bgmod-uninstaller
    runHook postBuild
  '';

  doCheck = true;

  nativeCheckInputs = [
    curl
  ];

  checkPhase = ''
    # test-logic
    HOME=$(mktemp -d) lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B tests/logic/logic_tests.lpi --widgetset=qt6
    patchelf ./tests/logic/logic_tests --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
    ./tests/logic/logic_tests
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --suffix PATH : ${
        lib.makeBinPath [
          bash # sh
          coreutils # cp, chmod, nohup, ln, mv, uname, sha256sum
          curl
          git
          glib # gdbus
          gnugrep # grep
          gnused # sed
          iproute2 # ip
          kmod # lsmod
          libnotify # notify-send (fallback)
          mangohud
          p7zip # 7z
          pciutils # lspci
          polkit # pkexec
          procps # pgrep
          psmisc # killall
          which
          xdg-utils # xdg-open
        ]
      }
    )
    patchelf $out/libexec/goverlay --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
    patchelf $out/libexec/pascube --set-rpath ${
      lib.makeLibraryPath [
        libx11
        libz
        SDL2
      ]
    }
    patchelf $out/libexec/bgmod-splash --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open source project that aims to create a Graphical UI to help manage Linux overlays";
    homepage = "https://github.com/benjamimgois/goverlay";
    changelog = "https://github.com/benjamimgois/goverlay/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ RoGreat ];
    mainProgram = "goverlay";
    platforms = lib.platforms.linux;
  };
})
