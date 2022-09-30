# ChatLoader
Loads an exported WhatsApp chat file ("WhatsApp Chat - [chatname].zip") to CoreData (MySQL).

This project the foundation for apps on the App Store such as [ChatPDF](https://apps.apple.com/us/app/chatpdf-pdf-chats-converter/id1499421936) and [ChatShots](https://apps.apple.com/us/app/chatshots/id1018833033)

## Installation
### Manual
Download all the project files and run it in Xcode.

Tested on: 
- Xcode Version 12.5.1 (12E507) 
- WhatsApp v2.21.110.15

## Usage
### iOS Device
1. Open WhatsApp
2. Swipe left on the WhatsApp chat to export
3. Tap "More"
4. Tap "Export Chat"
5. Tap "Without Media"
6. Tap ChatLoader from the 'Share menu' (note you may have to swipe to the right and select "More" then add ChatLoader to the list of apps that appear on the 'Share menu')
7. ...
8. Profit $$!

### Simulator
1. Run the ChatLoader project
2. Press the UI Button "Load chat from file system"
3. Note the directory printed to the console
4. Place the "WhatsApp Chat - [chatname].zip" in the directory listed in Step 3
5. Press the UI Button "Load chat from file system"
6. ...
7. Profit $$!

## Contributing
Pull requests are welcome.

## License
This project is released under the [MIT](https://choosealicense.com/licenses/mit/) license/

## Acknowledgements
- WPMedia for creating [WPZipArchive](https://github.com/WPMedia/WPZipArchive) (Note that WPZipArchive can be swapped out for any preferred archiving library).


