{ lib, ... }@arg: let
  removeNonConfigDirs =
    # TODO don't remove template during CI
    lib.flip builtins.removeAttrs ["lib" "modules" "template"];
in {
  imports =
      (lib.mapAttrsToList
        (name: _type: let
          path = ./. + "/${name}";
        in {
          _file = toString path;
          krebs = import path arg;
        })
        (removeNonConfigDirs
          (lib.filterAttrs
            (name: type: type == "directory" && !lib.hasPrefix "." name)
            (builtins.readDir ./.))));
}
