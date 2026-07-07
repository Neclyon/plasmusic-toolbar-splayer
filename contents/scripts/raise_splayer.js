// KWin script: find SPlayer window by caption and bring it to front
var clients = workspace.windowList();
for (var j = 0; j < clients.length; j++) {
    if (clients[j].caption.indexOf("SPlayer") !== -1) {
        workspace.activeWindow = clients[j];
        break;
    }
}
