import QtQuick
import Quickshell

import qs.common
import qs.services
import qs.modules.wallpaper
import qs.modules.session

ShellRoot {
    Component.onCompleted: {
        void Appearance;
        void NiriService;
        void SessionService;
    }

    Wallpaper {}
    SessionCurtain {}
}
