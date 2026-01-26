{ mkShell, nodejs_22, typescript, vtsls, bun, biome, typescript-language-server }:

mkShell {
  packages = [
    nodejs_22
    typescript
    vtsls
    typescript-language-server
    bun
    # Linter, Formatterなど。
    biome
  ];
}
