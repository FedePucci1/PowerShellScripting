# PowerShell directory watcher

Academic PowerShell script by Federico Pucci. Uses `System.IO.FileSystemWatcher` to monitor a directory and its subdirectories and react to file changes.

## Examples

The actual parameter names are `codigo`, `acciones` and `salida`:

```powershell
.\Script.ps1 -codigo .\Carpeta -acciones listar,peso
.\Script.ps1 -codigo .\Carpeta -acciones listar,compilar,publicar -salida .\Salidas
Get-Help .\Script.ps1 -Full
```

- `listar`: reports changed files.
- `peso`: reports file sizes.
- `compilar`: builds the exercise's aggregated output file; it is not a programming-language compiler.
- `publicar`: copies the generated output to the selected directory; requires `compilar`.

The original sample inputs are in `Pruebas.zip`. The implementation is preserved from the academic exercise. The publication review validates PowerShell parsing, not the full long-running watcher workflow. Use disposable sample directories when trying the file-writing actions.
