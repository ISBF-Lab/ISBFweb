# frozen_string_literal: true

module ::IsbfJoin
  class Application < ActiveRecord::Base
    self.table_name = "isbf_join_applications"

    include ApplicationFields
  end
end

# == Schema Information
#
# Table name: isbf_join_applications
#
#  id            :bigint           not null, primary key
#  name          :string(60)       not null
#  phone         :string(30)       not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  student_id    :string(40)       not null
#  submission_id :uuid             not null
#
# Indexes
#
#  index_isbf_join_applications_on_created_at_and_id  (created_at,id)
#  index_isbf_join_applications_on_submission_id      (submission_id) UNIQUE
#
