# Zen Browser

Add this to your `flake.nix`

```nix
inputs = {
  zen-browser.url = "github:loyaall/zen-browser-nixos-flake";
  ...
}
```

## Packages

Add this to a package list:

```nix
inputs.zen-browser.packages."${system}".default
```

To run it, do

```bash
zen
```
