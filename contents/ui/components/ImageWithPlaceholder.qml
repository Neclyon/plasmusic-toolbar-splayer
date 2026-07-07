import QtQuick
import QtQuick.Window

Image {
    id: imageWithPlaceholder

    property string placeholderSource
    property string imageSource
    property bool imageLoadFailed: false

    mipmap: true

    onImageSourceChanged: {
        // Reset the flag when the image URL changes
        imageLoadFailed = false
    }

    onStatusChanged: {
        if (status === Image.Error) {
            imageLoadFailed = true;
        }
    }

    source: imageLoadFailed || !imageSource ? placeholderSource : imageSource
}