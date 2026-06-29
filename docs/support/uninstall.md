# Uninstall

1. If Launch at Login is enabled, open Settings -> General and turn it off.
2. Quit MenuBarDeclutter from the status menu.
3. Remove the app bundle:
   ```sh
   rm -rf /Applications/MenuBarDeclutter.app
   ```
4. Optional: remove local app data:
   ```sh
   rm -rf "$HOME/Library/Application Support/MenuBarDeclutter"
   ```
5. Optional: remove local preferences:
   ```sh
   defaults delete Yongjun-Zhang.MenuBarDeclutter
   ```

MenuBarDeclutter does not install kernel extensions, login helpers, network agents, or cloud services.

If you are uninstalling a dry-run test build, Gatekeeper or stapler warnings from that build are expected and do not require cleanup beyond removing the app bundle and optional local data.
