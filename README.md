# dotfiles

Mi configuración de shell (PowerShell + oh-my-posh estilo Ubuntu) y de VS Code para Windows.

## Qué incluye

| Ruta | Contenido |
|------|-----------|
| `powershell/Microsoft.PowerShell_profile.ps1` | Perfil único para Windows PowerShell 5.1 y PowerShell 7+: oh-my-posh, PSReadLine (modo Emacs, predicciones), Terminal-Icons, alias tipo Linux (`ll`, `la`, `which`, `touch`), `Show-Tree`, `Kill-Port` |
| `powershell/scripts/Kill-Port.ps1` | Mata los procesos que escuchan en un puerto TCP (requiere admin) |
| `oh-my-posh/ubuntu.omp.json` | Tema del prompt |
| `vscode/settings.json` | Ajustes **filtrados** de VS Code (apariencia, formateadores, terminal) |
| `vscode/keybindings.json` | Atajos de teclado |
| `vscode/extensions.txt` | Extensiones instaladas |
| `bootstrap.ps1` | Instala todo y enlaza los archivos |

## Instalación en un equipo nuevo

```powershell
git clone https://github.com/santiagovasquez1/dotfiles $HOME\dotfiles
cd $HOME\dotfiles
.\bootstrap.ps1
```

Si falla por la política de ejecución:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Opciones de `bootstrap.ps1`:

- `-SkipPackages`: no instala nada con winget ni módulos.
- `-SkipExtensions`: no instala extensiones de VS Code.
- `-Copy`: copia los archivos en vez de crear symlinks. Los symlinks necesitan el **Modo desarrollador** de Windows (Configuración → Para programadores) o una terminal como administrador.

Los archivos que ya existan se respaldan como `*.bak`. El `settings.json` de VS Code **no** se sobrescribe si ya existe.

## Actualizar

Como los archivos están enlazados, basta con editar en el repo y hacer `git pull` en los otros equipos.

Para refrescar la lista de extensiones:

```powershell
code --list-extensions | Set-Content vscode\extensions.txt -Encoding utf8
```

## Qué NO está en este repo (a propósito)

Este repo es público. Por eso `vscode/settings.json` es una versión filtrada y no incluye conexiones a bases de datos, cuentas, tenants, rutas de usuario ni `mcp.json`. Para sincronizar eso entre equipos usa **Settings Sync** de VS Code (cuenta de icono → *Turn on Settings Sync*).

Nunca subas tokens, contraseñas ni archivos `.env` a este repo.
