import QtQuick

// Service entry point for the tray plugin.
//
// The shell hands third-party bar widgets a PluginBarApi facade that carries
// no widget registry, but it still injects the bar widget catalogue into a
// plugin's service entry point. This object exists to receive that
// catalogue. Tray.qml reads it back through bar.shell.serviceFor(<own id>)
// and instantiates the captured widgets from it.
//
// It lives in its own directory on purpose. The QML type loader caches a
// directory listing the first time it loads a file from it, and a file added
// later to a cached directory fails to load with "File name case mismatch"
// until the shell restarts. `omarchy plugin update` only rescans, so an
// upgrade that added Service.qml next to Tray.qml would leave the drawer
// empty until the next login. A new directory has no stale listing.
QtObject {
  property var shell: null
  property var manifest: null
  property var barWidgetRegistry: null
}
