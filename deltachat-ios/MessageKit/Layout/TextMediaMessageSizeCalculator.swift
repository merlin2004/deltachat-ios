/*
 MIT License

 Copyright (c) 2017-2019 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import UIKit

open class TextMediaMessageSizeCalculator: MessageSizeCalculator {

    private var maxMediaItemHeight: CGFloat {
        return UIScreen.main.bounds.size.height * 0.7
    }

    private let minTextWidth: CGFloat = 180

    public var incomingMessageLabelInsets = UIEdgeInsets(top: TextMediaMessageCell.insetTop,
                                                         left: TextMediaMessageCell.insetHorizontalBig,
                                                         bottom: TextMediaMessageCell.insetBottom,
                                                         right: TextMediaMessageCell.insetHorizontalSmall)
    public var outgoingMessageLabelInsets = UIEdgeInsets(top: TextMediaMessageCell.insetTop,
                                                         left: TextMediaMessageCell.insetHorizontalSmall,
                                                         bottom: TextMediaMessageCell.insetBottom,
                                                         right: TextMediaMessageCell.insetHorizontalBig)

    public var messageLabelFont = UIFont.preferredFont(forTextStyle: .body)

    internal func messageLabelInsets(for message: MessageType) -> UIEdgeInsets {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessageLabelInsets : incomingMessageLabelInsets
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        let maxImageWidth = messageContainerMaxWidth(for: message)

        let sizeForMediaItem = { (maxWidth: CGFloat, item: MediaItem) -> CGSize in
            var maxTextWidth = maxWidth - self.messageLabelInsets(for: message).horizontal
            var imageHeight = item.size.height
            var imageWidth = item.size.width

            if maxWidth < item.size.width {
                // Maintain the ratio if width is too great
                imageHeight = maxWidth * item.size.height / item.size.width
                imageWidth = maxWidth
            }

            if self.maxMediaItemHeight < imageHeight {
                // Maintain the ratio if height is too great
                imageWidth = self.maxMediaItemHeight * imageWidth / imageHeight
                imageHeight = self.maxMediaItemHeight
                maxTextWidth = imageWidth - self.messageLabelInsets(for: message).horizontal

            }

            if imageWidth < self.minTextWidth {
                // if text will be too narrow, increase again the size
                imageHeight = self.minTextWidth * imageHeight / imageWidth
                imageWidth = self.minTextWidth
                maxTextWidth = imageWidth - self.messageLabelInsets(for: message).horizontal
            }

            var messageContainerSize = CGSize(width: imageWidth, height: imageHeight)
            switch message.kind {
            case .photoText(let mediaItem), .animatedImageText(let mediaItem):
                if let text = mediaItem.text?[MediaItemConstants.messageText] {
                    let textHeight = text.height(withConstrainedWidth: maxTextWidth)
                    messageContainerSize.height += textHeight
                    messageContainerSize.height +=  self.messageLabelInsets(for: message).vertical
                }
                return messageContainerSize
            case .videoText(let mediaItem):
                var videoContainerSize = CGSize(width: self.minTextWidth, height: self.minTextWidth)
                if let text = mediaItem.text?[MediaItemConstants.messageText] {
                    let textHeight = text.height(withConstrainedWidth: maxTextWidth)
                    // static size for thumbnails
                    videoContainerSize.height += textHeight
                    videoContainerSize.height += self.messageLabelInsets(for: message).vertical
                }
                return videoContainerSize
            default:
                return messageContainerSize
            }
        }

        switch message.kind {
        case .photoText(let item), .videoText(let item), .animatedImageText(let item):
            return sizeForMediaItem(maxImageWidth, item)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }

    open override func configure(attributes: UICollectionViewLayoutAttributes) {
        super.configure(attributes: attributes)
        guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

        let dataSource = messagesLayout.messagesDataSource
        let indexPath = attributes.indexPath
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)

        switch message.kind {
        case .photoText, .videoText, .animatedImageText:
            attributes.messageLabelInsets = messageLabelInsets(for: message)
            attributes.messageLabelFont = messageLabelFont
        default:
            break
        }
    }


}
