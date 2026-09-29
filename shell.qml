import QtQuick
import Quickshell

import qs.common
import qs.services
import qs.modules.wallpaper
import qs.modules.session
import qs.modules.corners

ShellRoot {
    Component.onCompleted: {
        void Appearance;
        void NiriService;
        void SessionService;
    }

    Wallpaper {}
    ScreenCorners {}
    SessionCurtain {}
}
