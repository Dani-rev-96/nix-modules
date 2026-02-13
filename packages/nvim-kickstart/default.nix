{
  lib,
  stdenv,
  pkgs,
}:

let
  custom = ./config;
in
stdenv.mkDerivation {
  pname = "nvim-kickstart";
  version = "1.0.0";

  src = custom;

  installPhase = ''
    mkdir $out
    cp -r * "$out/"
  '';
}
