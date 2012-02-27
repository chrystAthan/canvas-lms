#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20120227194305_reassociate_conversation_attachments.rb'

describe ReassociateConversationAttachments do
  describe "up" do
    it "should work" do
      c = Conversation.create!

      u1 = user
      cm1 = c.conversation_messages.build
      cm1.author_id = u1.id
      cm1.body = ''
      cm1.save_without_broadcasting!
      a1 = attachment_obj_with_context(cm1)
      a1.save_without_touching_context

      # this will set up the conversation attachments folder (and my files folder)
      u1.conversation_attachments_folder
      u1.folders.map(&:name).sort.should eql ["conversation attachments", "my files"]

      u2 = user
      cm2 = c.conversation_messages.build
      cm2.author_id = u2.id
      cm2.body = ''
      cm2.save_without_broadcasting!
      a2 = attachment_obj_with_context(cm2)
      a2.save_without_touching_context
      a3 = attachment_obj_with_context(cm2)
      a3.save_without_touching_context
      u2.folders.should be_empty

      ReassociateConversationAttachments.up

      u1.reload
      u1.folders.map(&:name).sort.should eql ["conversation attachments", "my files"]
      u1.conversation_attachments_folder.attachments.should eql [a1]
      cm1.reload
      a1.reload
      cm1.attachment_ids.should eql a1.id.to_s
      cm1.attachments.should eql [a1]
      a1.context.should eql u1

      u2.reload
      u2.folders.map(&:name).sort.should eql ["conversation attachments", "my files"]
      u2.conversation_attachments_folder.attachments.map(&:id).sort.should eql [a2.id, a3.id]
      cm2.reload
      a2.reload
      a3.reload
      cm2.attachment_ids.split(',').map(&:to_i).sort.should eql [a2.id, a3.id]
      cm2.attachments.should eql [a2, a3]
      a2.context.should eql u2
      a3.context.should eql u2
    end
  end
end
