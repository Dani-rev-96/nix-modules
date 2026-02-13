{
  lib,
  fetchFromGitHub,
  rocmPackages,
  python3,
  cargo,
  rustc,
  cmake,
  clang,
  zlib,
  libxml2,
  libedit,
  rustPlatform,
  stdenv,
  pkg-config,
}:

rustPlatform.buildRustPackage rec {
  pname = "zluda";
  version = "6-preview.20260121";

  src = fetchFromGitHub {
    owner = "vosen";
    repo = "ZLUDA";
    rev = "a5ecf6ae8fc46da84ed906ad9fbfb5a1a53742ef";
    hash = "sha256-vQYAA8/eVYCXUknRQ4cmgWlbIjpGwm16AUROoS5nlO4=";
    fetchSubmodules = true;
  };

  buildInputs = [
    rocmPackages.clr
    rocmPackages.miopen
    rocmPackages.rocm-smi
    rocmPackages.rocsparse
    rocmPackages.rocsolver
    rocmPackages.rocblas
    rocmPackages.hipblas
    rocmPackages.rocm-cmake
    rocmPackages.hipfft
    rocmPackages.hipblaslt
    zlib
    libxml2
    libedit
    pkg-config
  ];

  nativeBuildInputs = [
    python3
    cargo
    rustc
    cmake
    clang
  ];

  cargoHash = "sha256-YNBeweZ/vfXGfM0lrZbAh71z6Rb0+B7nOuO8VL2BmCo=";

  # xtask doesn't support passing --target, but nix hooks expect the folder structure from when it's set
  env.CARGO_BUILD_TARGET = stdenv.hostPlatform.rust.cargoShortTarget;
  env.CMAKE_BUILD_TYPE = "Release";

  # cmakeFlags = [
  #   "-DCMAKE_BUILD_TYPE=Release"
  # ];

  preConfigure = ''
    # disable test written for windows only: https://github.com/vosen/ZLUDA/blob/774f4bcb37c39f876caf80ae0d39420fa4bc1c8b/zluda_inject/tests/inject.rs#L55
    rm -r zluda_inject/tests
  '';

  doCheck = false;

  buildPhase = ''
    runHook preBuild
    cargo xtask --release
    runHook postBuild
  '';

  preInstall = ''
    mkdir -p $out/lib/
    find target/release/ -maxdepth 1 -type l -name '*.so*' -exec \
      cp --recursive --no-clobber --target-directory=$out/lib/ {} +
    mkdir -p $out/include/
    find target/ -maxdepth 3 -type l -name '*.h*' -exec \
      cp --recursive --no-clobber --target-directory=$out/include/ {} +
  '';

  meta = {
    description = "ZLUDA - CUDA on non-Nvidia GPUs";
    homepage = "https://github.com/vosen/ZLUDA";
    changelog = "https://github.com/vosen/ZLUDA/releases/tag/${src.rev}";
    license = lib.licenses.mit;
    maintainers = [
      lib.maintainers.errnoh
    ];
  };
}
