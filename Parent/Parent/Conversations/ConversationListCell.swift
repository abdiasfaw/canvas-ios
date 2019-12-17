//
// This file is part of Canvas.
// Copyright (C) 2019-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import Core

class ConversationListCell: UITableViewCell {
    @IBOutlet weak var contextLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var unreadView: UIView!

    func update(_ conversation: Conversation) {
        unreadView.isHidden = conversation.workflowState != .unread
        let subject = !conversation.subject.isEmpty
            ? conversation.subject
            : NSLocalizedString("(No subject)", comment: "")
        subjectLabel.text = subject
        dateLabel.text = conversation.lastMessageAt.dateMediumString
        contextLabel.text = conversation.contextName
        lastMessageLabel.text = conversation.lastMessage

        accessibilityIdentifier = "ConversationListCell.\(conversation.id)"
        accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("%@, %@, last message %@ %@", comment: "label for conversation row with context, subject, & last message date & text"),
            conversation.contextName,
            subject,
            conversation.lastMessageAt.dateMediumString,
            conversation.lastMessage
        )
        if conversation.workflowState == .unread {
            accessibilityLabel = String.localizedStringWithFormat(
                NSLocalizedString("%@, unread", comment: "added to conversation label when unread"),
                accessibilityLabel!
            )
        }
    }
}
