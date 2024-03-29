//=============================================================================
//
//  MEI Export Plugin
//  Based on ABC Export Plugin: https://musescore.org/en/project/abc-export
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//=============================================================================
import QtQuick 2.9
import QtQuick.Controls 2.2
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
    width:  500
    height: 400

    onRun: {
        directorySelectDialog.folder = ((Qt.platform.os == "windows") ? "file:///" : "file://") + exportDirectory.text;
        exportServerTextField.text = settings.exportServer ? settings.exportServer : "https://mscore-plugin.verovio.org/mei";

    }

    Component.onDestruction: {
        settings.exportDirectory = exportDirectory.text
    }

     SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }
     property color system_text_color: myPalette.text    
    
    Settings {
        id: settings
        category: "Plugin-MEIexport"
        property alias exportServer: exportServerTextField.text
        property alias exportDirectory: exportDirectory.text
        property alias basic: meiBasicCheck.checked
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
            color: system_text_color
        }

        TextField {
            Layout.preferredWidth: 250
            id: exportServerTextField
            text: ""
            enabled: true
        }

        Button {
            id: selectDirectory
            text: qsTranslate("ScoreComparisonTool", "Export Location")
            onClicked: {
                directorySelectDialog.open();
            }
            contentItem: Text {
                text: parent.text
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.down ? "#bbbbbb" :
                        (parent.hovered ? "#d6d6d6" : "#f6f6f6")
            }
        }
        Label {
            id: exportDirectory
            text: ""
            color: system_text_color
        }

        CheckBox {
            id: meiBasicCheck
            Layout.columnSpan: 2
            checked: false
            text: "Export MEI Basic"
            contentItem: Text {
                leftPadding: meiBasicCheck.indicator && !meiBasicCheck.mirrored ? meiBasicCheck.indicator.width + meiBasicCheck.spacing : 0
                rightPadding: meiBasicCheck.indicator && meiBasicCheck.mirrored ? meiBasicCheck.indicator.width + meiBasicCheck.spacing : 0

                text: meiBasicCheck.text
                color: system_text_color
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
        }

        Button {
            id: exportButton
            Layout.columnSpan: 2
            text: qsTranslate("ExportDialog", "Export")
            contentItem: Text {
                text: parent.text
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.down ? "#bbbbbb" :
                        (parent.hovered ? "#d6d6d6" : "#f6f6f6")
            }
            onClicked: {
                exportButton.text = qsTranslate("Ms::MuseScore", "Exporting…");
                statusText.text = statusText.text + "Starting export using " + exportServerTextField.text + '\n'
                // Create MusicXML
                tempXMLFile.source = tempXMLFile.tempPath() + "//" + "tempExport.xml";
                writeScore(curScore, tempXMLFile.source, "xml");
                var exportFilename = exportDirectory.text + "//" + curScore.scoreName.replace(/ /g, "_") + ".mei"
                statusText.text = statusText.text + "Exporting to file: " + exportFilename + '\n'

                var request = new XMLHttpRequest();
                var boundary = '---------------------------' + genRandom();

                var body = '';
                // body += "Content-Type: multipart/form-data; boundary=" + boundary + "\n";
                body += '--' + boundary + '\r\n' + 'Content-Disposition: form-data; name="content"; filename="test.musicxml"\n';
                body += "Content-Type: application/octet-stream\r\n\r\n"
                body += tempXMLFile.read();
                body += '\r\n\r\n';
                body += '--' + boundary + '--';

                var transformationServer = exportServerTextField.text;
                if (meiBasicCheck.checked)
                {
                    statusText.text = statusText.text + "Producing MEI Basic\n"
                    transformationServer = transformationServer + "?basic=true";
                }

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
                              statusText.text = statusText.text + "File written to " + exportedMEIFile.source + "\n"
                              break;
                        default:
                              console.log("An error occurred. Status code " + request.status)
                              statusText.text = statusText.text + "An error occurred. Server status code: " + request.status + "\n"
                              break;
                        }

                        // Done
                        exportButton.text = qsTranslate("ExportDialog", "Export");
                        statusText.text = statusText.text + "Finished export\n"
                        // pluginDialog.parent.Window.window.close();
                    }
                });
                request.open("POST", exportServerTextField.text, true);
                request.setRequestHeader("content-type", 'multipart/form-data; boundary=' + boundary + '; charset=UTF-8');
                request.send(body);
                statusText.text = statusText.text + "File uploaded\n"

          }
        }


        ScrollView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: 2
            TextArea {
                id: statusText
                anchors.fill: parent
                readOnly: true
                text: ""
                background: Rectangle {
                    color: "white"
                    border.color: "#C0C0C0"
                }
            }

            ScrollBar.vertical: ScrollBar {
                parent: view
                width: 20
                x: view.mirrored ? 0 : view.width - width
                y: view.topPadding
                height: view.availableHeight
                active: true
                interactive: true
                visible: true
            }
        }
    }
}
