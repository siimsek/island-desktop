// Pencere yokken alttaki paneli (dock) gizle, pencere varken goster.
var lastState = null;

function countWindows() {
    var n = 0;
    var list = workspace.windowList();
    for (var i = 0; i < list.length; ++i) {
        var w = list[i];
        if (w.normalWindow && !w.skipTaskbar && !w.desktopWindow && !w.dock) n++;
    }
    return n;
}

function update() {
    var hasWindows = countWindows() > 0;
    if (hasWindows === lastState) return;
    lastState = hasWindows;
    // autohide kenara gelince tekrar aciliyordu; bos iken paneli en kucuk boyuta cekiyoruz.
    var h = hasWindows ? 62 : 1;
    var js = "for (var i = 0; i < panels().length; ++i) { var p = panels()[i]; " +
             "if (p.location == 'bottom') { p.hiding = 'dodgewindows'; p.height = " + h + "; } }";
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", js);
}

workspace.windowAdded.connect(update);
workspace.windowRemoved.connect(update);
update();
