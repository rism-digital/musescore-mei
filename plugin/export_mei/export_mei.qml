import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.1
import Qt.labs.settings 1.0

import MuseScore 3.0
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.MEI Export"
    version: "1.0.0"
    description: qsTr("This plugin exports the current score to an MEI file. An internet connection is required.")
    requiresScore: true
    pluginType: "dialog"

    id: pluginDialog
    width:  400
    height: 120

    onRun: {
        directorySelectDialog.folder = ((Qt.platform.os == "windows")? "file:///" : "file://") + exportDirectory.text;
    }

    Component.onDestruction: {
        settings.exportDirectory = exportDirectory.text
    }

    Settings {
        id: settings
        category: "Plugin-MEIexport"
        property alias exportDirectory: exportDirectory.text
    }

    FileDialog {
        id: directorySelectDialog
        title: qsTranslate("MS::PathListDialog", "Choose a directory")
        selectFolder: true
        visible: false
        onAccepted: {
            exportDirectory.text = this.folder.toString().replace("file://", "").replace(/^\/(.:\/)(.*)$/, "$1$2");
        }
        Component.onCompleted: visible = false
    }

    FileIO {
        id: tempXMLFile
        onError: console.log(msg)
    }

    FileIO {
        id: exportedMEIFile
        onError: console.log(msg)
    }

    function genRandom()
    {
        var ret = [];
        var len = 16;

        for (var i = 0; i < len; i++)
        {
            ret.push(Math.floor(Math.random() * 16).toString(16));
        }

        return ret.join('');
    }

    GridLayout {
        columns: 2
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: qsTr("Export server") + ":"
        }
        RowLayout {
            TextField {
                Layout.preferredWidth: 250
                id: exportServer
                text: "http://localhost:8009/mei"
                enabled: true
                //                //color: sysActivePalette.text
                //                color: rdbImport.checked ? sysDisabledPalette.shadow : sysDisabledPalette.mid //sysDisabledPalette.buttonText
            }
        }

        Button {
            id: selectDirectory
            text: qsTranslate("ScoreComparisonTool", "Browse")
            onClicked: {
                directorySelectDialog.open();
            }
        }
        Label {
            id: exportDirectory
            text: ""
        }

        Button {
            id: exportButton
            Layout.columnSpan: 2
            text: qsTranslate("ExportDialog", "Export")
            onClicked: {
                exportButton.text = qsTranslate("Ms::MuseScore", "Exporting…");

                // Create MusicXML
                tempXMLFile.source = tempXMLFile.tempPath() + "//" + "tempExport.xml";
                writeScore(curScore, tempXMLFile.source, "xml");
                var exportFilname = exportDirectory.text + "//" + curScore.scoreName.replace(/ /g, "_") + ".mei"


                var request = new XMLHttpRequest();
                var boundary = '---------------------------' + genRandom();

                var body = '';
                // body += "Content-Type: multipart/form-data; boundary=" + boundary + "\n";
                body += '--' + boundary + '\r\n' + 'Content-Disposition: form-data; name="content"; filename="test.musicxml"\n';
                body += "Content-Type: application/octet-stream\r\n\r\n"
                body += tempXMLFile.read();
                body += '\r\n\r\n'
                body += '--' + boundary + '--';

                request.onreadystatechange = (function() {
                    if (request.readyState == XMLHttpRequest.DONE)
                    {
                        console.log(request.status);
                        switch(request.status)
                        {
                        case 200:
                              // Save
                              exportedMEIFile.source = exportDirectory.text + "//" + curScore.scoreName.replace(/ /g, "_") + ".mei";
                              exportedMEIFile.write(request.responseText);
                              break;
                        default:
                              console.log("An error occurred. Status code " + request.status)
                              break;
                        }

                        // Done
                        exportButton.text = qsTranslate("ExportDialog", "Export");
                        pluginDialog.parent.Window.window.close();
                    }
                });
                request.open("POST", exportServer.text, true);
                request.setRequestHeader("content-type", 'multipart/form-data; boundary=' + boundary + '; charset=UTF-8');
                request.send(body);
          }
        }
    }
}
