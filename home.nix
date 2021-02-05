{ config, pkgs, ... }:

let
  dag = config.lib.dag;
  unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};
  thunar = pkgs.xfce.thunar.override { thunarPlugins = [pkgs.xfce.thunar-archive-plugin]; };
  python = pkgs.python3.withPackages (ps: with ps; [ youtube-dl pynvim ]);
  dwarf-fortress = unstable.dwarf-fortress-packages.dwarf-fortress-full.override {
    enableIntro = false;
    enableSound = false;
    enableSoundSense = false;
    enableStoneSense = false;
  };

  nativeI3lock = pkgs.writers.writeBashBin "i3lock" ''
    PATH=/usr/bin:${pkgs.i3lock}/bin i3lock "$@"
  '';

in
{
  programs.home-manager.enable = true;
  home.stateVersion = "20.03";

  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    tmux
    pv
    pstree
    asciinema
    bat
    clojure
    cowsay
    curl
    direnv
    entr
    feh
    fish
    gcc
    git
    gitflow
    gnumake
    htop
    httpie
    joker
    killall
    lazygit
    leiningen
    maven
    netcat-gnu
    nodejs
    python
    ripgrep
    stow
    tree
    unstable.fzf
    unstable.janet
    unstable.luajit
    unstable.luarocks
    unstable.neovim # neovim-nightly
    unstable.racket
    unzip
    xmlformat
    weechat

    # Heavy GUI based things.
    # May want to comment these out in headless environments.
    #fbida
    baobab
    dwarf-fortress
    fira-code
    fira-code-symbols
    firefox
    gimp
    glibcLocales
    #i3lock
    #i3status
    lastpass-cli
    networkmanagerapplet
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    rofi
    spotify
    thunar
    unstable.discord
    unstable.love_11
    unstable.obs-studio
    xclip
    xfce.xfce4-screenshooter
    xss-lock
    mpv
  ];

  home.activation.stow = dag.entryAfter [ "writeBoundary" ] ''
    cd $HOME/.config/nixpkgs
    stow --target=$HOME stowed
  '';

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
