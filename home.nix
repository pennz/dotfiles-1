{ config, pkgs, ... }:

let
  dag = config.lib.dag;
  unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};
  python = pkgs.python3.withPackages (ps: with ps; [ youtube-dl pynvim ]);

  nativeI3lock = pkgs.writers.writeBashBin "i3lock" ''
    PATH=/usr/bin:${pkgs.i3lock}/bin i3lock "$@"
  '';

in
{
  programs.home-manager.enable = true;
  home.stateVersion = "20.09";
  home.homeDirectory = "/home/pengyu";
  home.username = "pengyu";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
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
    #joker
    killall
    lazygit
    #leiningen
    #maven
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
    unzip
    xmlformat
    weechat

    # Heavy GUI based things.
    # May want to comment these out in headless environments.
  ];

  home.activation.stow = dag.entryAfter [ "writeBoundary" ] ''
    cd $HOME/.config/nixpkgs
    stow --target=$HOME stowed
  '';
}

