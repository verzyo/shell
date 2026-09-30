import QtQuick
import Quickshell

import qs.common
import qs.services
import qs.modules.wallpaper
import qs.modules.session
import qs.modules.corners
import qs.modules.bar

ShellRoot {
    Component.onCompleted: {
        void Appearance;
        void NiriService;
        void SessionService;
    }

    Wallpaper {}
    ScreenCorners {}
    Bar {}
    SessionCurtain {}
}
