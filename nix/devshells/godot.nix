{ mkShell, godot_4, godot_4-export-templates-bin, gdtoolkit_4 }:

mkShell {
  packages = [
    godot_4
    godot_4-export-templates-bin
    gdtoolkit_4
  ];
}
