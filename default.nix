{ lib, ... }@arg: let
  removeNonUserDirs =
    # `template` is scaffolding, `lib`/`modules` are infrastructure
    # added when kartei became a standalone flake — neither is a
    # user directory and must not be imported as one.
    # TODO don't remove template during CI
    lib.flip builtins.removeAttrs ["template" "lib" "modules"];
in {
  imports =
      (lib.mapAttrsToList
        (name: _type: let
          path = ./. + "/${name}";
        in {
          _file = toString path;
          krebs = import path arg;
        })
        (removeNonUserDirs
          (lib.filterAttrs
            (name: type: type == "directory" && !lib.hasPrefix "." name)
            (builtins.readDir ./.))));
}
