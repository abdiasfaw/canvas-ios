//
// Copyright (C) 2016-present Instructure, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/* @flow */

import { shallow } from 'enzyme'
import React from 'react'
import { ActionSheetIOS } from 'react-native'
import renderer from 'react-test-renderer'
import explore from '../../../../../test/helpers/explore'
import Reply, { type Props } from '../Reply'

jest.mock('Button', () => 'Button').mock('TouchableHighlight', () => 'TouchableHighlight').mock('TouchableOpacity', () => 'TouchableOpacity')

const template = {
  ...require('../../../../__templates__/discussion'),
  ...require('../../../../__templates__/users'),
  ...require('../../../../__templates__/helm'),
  ...require('../../../../__templates__/session'),
}
jest.mock('WebView', () => 'WebView')
  .mock('ActionSheetIOS', () => ({
    showActionSheetWithOptions: jest.fn(),
  }))
  .mock('../../../../common/components/Avatar', () => 'Avatar')

describe('DiscussionReplies', () => {
  let props: Props
  beforeEach(() => {
    let reply = template.discussionReply({ id: '1' })
    reply.replies = [template.discussionReply({ id: 2 })]
    let user = template.userDisplay()
    props = {
      reply: reply,
      depth: 0,
      readState: 'read',
      participants: { [user.id]: user },
      context: 'courses',
      contextID: '1',
      discussionID: '1',
      entryID: '1',
      deleteDiscussionEntry: jest.fn(),
      replyToEntry: jest.fn(),
      myPath: [0],
      navigator: template.navigator(),
      onPressMoreReplies: jest.fn(),
      maxReplyNodeDepth: 2,
      discussionLockedForUser: false,
      rating: null,
      showRating: false,
      canRate: false,
      rateEntry: jest.fn(),
    }
  })

  it('renders', () => {
    testRender(props)
  })

  it('renders deleted', () => {
    props.reply.deleted = true
    testRender(props)
  })

  it('renders with no user', () => {
    props.reply.user_id = ''
    props.reply.editor_id = ''
    testRender(props)
  })

  it('renders with closed discussion as student', () => {
    props.discussionLockedForUser = true
    testRender(props)
  })

  it('navigates to the context card when an avatar is pressed', () => {
    let avatar = explore(render(props).toJSON()).selectByID('reply.avatar') || {}
    avatar.props.onPress()
    expect(props.navigator.show).toHaveBeenCalledWith(
      `/courses/1/users/1`,
      { modal: true },
    )
  })

  it('actionMore', () => {
    props.depth = 2
    props.reply.replies = [template.discussionReply({ id: 2 }), template.discussionReply({ id: 3 }), template.discussionReply({ id: 4 })]
    let replyButton = explore(render(props).toJSON()).selectByID('discussion.more-replies') || {}
    replyButton.props.onPress()
    expect(props.onPressMoreReplies).toHaveBeenCalledWith([0])
  })

  it('renders more button with some deleted replies', () => {
    let a = template.discussionReply({ id: '2' })
    let b = template.discussionReply({ id: '3' })
    let c = template.discussionReply({ id: '4', deleted: true })

    let reply = template.discussionReply({ id: '1', replies: [a, b, c] })
    props.reply = reply
    props.depth = 3
    testRender(props)
  })

  it('edit action sheet calls delete', () => {
    testEditActionSheet(1)
    expect(props.deleteDiscussionEntry).toHaveBeenCalledWith('courses', '1', '1', '1', [0])
  })

  it('edit action sheet calls cancel', () => {
    let reply = render(props).getInstance()
    reply._actionEdit()
    // $FlowFixMe
    ActionSheetIOS.showActionSheetWithOptions.mock.calls[0][1](2)
    expect(ActionSheetIOS.showActionSheetWithOptions).toHaveBeenCalled()
    expect(render(props).toJSON()).toMatchSnapshot()
  })

  it('edit action sheet calls edit', () => {
    testEditActionSheet(0)
    expect(props.navigator.show).toHaveBeenCalledWith('/courses/1/discussion_topics/1/reply', { modal: true }, { message: props.reply.message, entryID: props.reply.id, isEdit: true, indexPath: props.myPath })
  })

  it('reply to entry', () => {
    let reply = render(props).getInstance()
    reply._actionReply()
    expect(props.replyToEntry).toHaveBeenCalledWith('1', [0])
  })

  describe('ratings', () => {
    beforeEach(() => {
      props.reply = template.discussionReply({ id: '1', rating_sum: 2 })
    })

    it('renders rating', () => {
      props.showRating = true
      props.canRate = true
      testRender(props)
    })

    it('renders user rating', () => {
      props.showRating = true
      props.canRate = true
      props.rating = 1
      testRender(props)
    })

    it('renders rating when user cant rate', () => {
      props.showRating = true
      props.canRate = false
      testRender(props)
    })

    it('renders rating after user rates for first time', () => {
      props.showRating = true
      props.canRate = true
      props.rating = null
      const view = shallow(<Reply {...props }/>)
      const rateBtn = view.find('[testID="discussion.reply.rate-btn"]')
      rateBtn.simulate('Press')
      view.update()
      expect(view).toMatchSnapshot()
    })

    it('renders rating after user updates rating', () => {
      props.showRating = true
      props.canRate = true
      props.rating = 1
      const view = shallow(<Reply {...props }/>)
      const rateBtn = view.find('[testID="discussion.reply.rate-btn"]')
      rateBtn.simulate('Press')
      view.update()
      expect(view).toMatchSnapshot()
    })
  })

  function testEditActionSheet (buttonIndex: number) {
    let reply = render(props).getInstance()
    reply._actionEdit()
    // $FlowFixMe
    ActionSheetIOS.showActionSheetWithOptions.mock.calls[0][1](buttonIndex)
    expect(ActionSheetIOS.showActionSheetWithOptions).toHaveBeenCalled()
  }

  function testRender (props: Props) {
    expect(render(props).toJSON()).toMatchSnapshot()
  }

  function render (props: Props): any {
    return renderer.create(<Reply {...props}/>)
  }

  it('shows attachment', () => {
    props.reply = Object.assign(props.reply, { attachment: { } })
    let tree = render(props)

    tree.getInstance().showAttachment()

    expect(props.navigator.show).toHaveBeenCalledWith(
      '/attachment',
      { modal: true },
      { attachment: props.reply.attachment }
    )
  })
})

