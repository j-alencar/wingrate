# Registry Reference

Settings applied by `base.dsc.yaml` (WinGet Configure) or `fallback_settings.yml` (win_regedit).

## Taskbar

| Setting | Registry Key |
|---|---|
| Alignment: left | `TaskbarAl` |
| Widgets: hidden | `TaskbarDa` |
| Chat icon: hidden | `TaskbarMn` |
| Task View: hidden | `ShowTaskViewButton` |
| Search box: hidden | `SearchboxTaskbarMode` |

## Explorer

| Setting | Registry Key |
|---|---|
| File extensions: hidden | `HideFileExt` |
| Hidden files: not shown | `Hidden` |
| System files: hidden | `ShowSuperHidden` |
| Thumbnails: shown | `IconsOnly` |
| Classic context menu | `{86ca1aa0-...}\InprocServer32` |
| Snap assist flyout: off | `EnableSnapAssistFlyout` |

## Theme

| Setting | Registry Key |
|---|---|
| App dark mode | `AppsUseLightTheme` |
| System dark mode | `SystemUsesLightTheme` |
| Transparency: off | `EnableTransparency` |

## Privacy

| Setting | Registry Key |
|---|---|
| Suggested content: off | `SubscribedContent-338393Enabled` |
| Tips and suggestions: off | `SubscribedContent-353694Enabled` |
| Start menu suggestions: off | `SubscribedContent-338388Enabled` |
| Advertising ID: off | `Enabled` (AdvertisingInfo) |
| Tailored experiences: off | `TailoredExperiencesWithDiagnosticDataEnabled` |

## Misc

| Setting | Registry Key |
|---|---|
| Clipboard history: on | `EnableClipboardHistory` |
| Window animations: off | `MinAnimate` |
| Drag full windows: on | `DragFullWindows` |
