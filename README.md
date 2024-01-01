# Temporal

A barebone operating system. It wouldn't be possible if I didn't find nanobyte!

## Roadmap

- [ ] Multi-stage Boot (asm to C)
- [ ] System I/O
- [ ] System filesys
- [ ] Mem protect

## NixOS Support

This operating system has been converted into a Nix flake. Note it does not support installation as a package because Temporal is not a package, obviously.


To build Temporal, simply run
```
nix build .
```
To run Temporal, run
```
nix develop .
make run
```

## What I've learned

If you want to build gcc and other repos on NixOS, remember
that **hardening** is automatically enabled.
To disable it, add `hardeningDisable = [ "all" ]` to the flake
according to this
[question](https://stackoverflow.com/questions/77249760/gcc-build-fails-due-a-warning-in-libcpp).


Also, `LD_LIBRARY_PATH` needs to be configured.
Luckily, a util function called `pkgs.lib.makeLibraryPath` helps with that!


We have to additionally refresh flake.lock sometimes
to prevent strange bugs from occurring.
