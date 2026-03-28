{
  description = "A flake to install zen-browser on nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      version = "1.19.5b";
      downloadUrl = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
      sha256 = "sha256:02fpkygvwqh89lwhhhbgvpyb7s15jlpbdyjblb2pf40m4qfi1s7m";

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      mkZenFor =
        system:
        let
          pkgs = pkgsFor system;
          runtimeLibs = with pkgs; [
            libGL
            libGLU
            libevent
            libffi
            libjpeg
            libpng
            libstartup_notification
            libvpx
            libwebp
            gcc-unwrapped
            fontconfig
            libxkbcommon
            zlib
            speechd
            freetype
            gtk3
            libxml2
            dbus
            xcb-util-cursor
            alsa-lib
            libpulseaudio
            pango
            atk
            cairo
            gdk-pixbuf
            glib
            udev
            libva
            mesa
            libnotify
            cups
            pciutils
            ffmpeg
            libglvnd
            pipewire
            libxcb
            libX11
            libXcursor
            libXrandr
            libXi
            libXext
            libXcomposite
            libXdamage
            libXfixes
            libXScrnSaver
          ];
        in
        pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "zen-browser";
          stdenv.hostPlatform.system = system;

          src = builtins.fetchTarball {
            url = downloadUrl;
            sha256 = sha256;
          };

          desktopSrc = ./.;

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.copyDesktopItems
            pkgs.wrapGAppsHook3
          ];

          installPhase = ''
            mkdir -p $out/bin && cp -r $src/* $out/bin
            install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
            install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          '';

          fixupPhase = ''
            chmod 755 $out/bin/*
            patchAndWrap() {
              local bin=$1
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$out/bin/$bin"
              wrapProgram "$out/bin/$bin" \
                --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                --set MOZ_LEGACY_PROFILES 1 \
                --set MOZ_ALLOW_DOWNGRADE 1 \
                --set MOZ_APP_LAUNCHER zen \
                --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            }
            patchAndWrap "zen"
            patchAndWrap "zen-bin"

            patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
            wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          '';

          meta.mainProgram = "zen";
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkZenFor system;
      });

      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.zen-browser;
        in
        {
          options.programs.zen-browser = {
            enable = lib.mkEnableOption "Zen Browser";
          };

          config = lib.mkIf cfg.enable {
            home.packages = [
              self.packages.${pkgs.system}.default
            ];
          };
        };
    };
}
