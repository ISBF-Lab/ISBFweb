# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF library isolation from academy resource permissions", type: :request do
  fab!(:category)
  fab!(:learning_category, :category)
  fab!(:admin)
  fab!(:delegate) { Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true) }
  fab!(:member) do
    Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
  end

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = learning_category.id
    SiteSetting.isbf_library_enabled = true
    SiteSetting.isbf_library_category_id = category.id
    [category, learning_category].each do |item|
      item.set_permissions(trust_level_0: :full, staff: :full)
      item.save!
    end
    academy_permissions =
      Module.new do
        def academy_can?(permission)
          %i[manage_resources review_resources].include?(permission)
        end
      end
    allow(Guardian).to receive(:new).and_wrap_original do |original, *args, **kwargs|
      guardian = original.call(*args, **kwargs)
      guardian.extend(academy_permissions) if guardian.user&.id == delegate.id
      guardian
    end
  end

  let(:course) { IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1) }
  let(:directory) { IsbfLibrary::Catalog.create(admin, kind: "category", name: "校园资料") }
  let(:group) do
    IsbfLibrary::Catalog.create(
      admin,
      kind: "group",
      name: "新生指南",
      category_id: directory.fetch("id"),
    )
  end

  def resource_payload(library)
    @number = (@number || 0) + 1
    {
      :title => "Academy permission reference #{@number}",
      :raw => "Reference https://example.org/academy.pdf",
      :category => library.category_id,
      library::GROUP_FIELD.to_sym => (library == IsbfLearning ? course : group).fetch("id"),
      library::FILES_FIELD.to_sym => "[]",
      library::LINK_FIELD.to_sym => "https://example.org/academy.pdf",
      library::DESCRIPTION_FIELD.to_sym => "Original description",
      library::CONTRIBUTOR_FIELD.to_sym => "资料小组",
    }
  end

  def post_result(actor, library)
    result = NewPostManager.new(actor, resource_payload(library)).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    result
  end

  it "delegates course helpers while keeping independent library helpers admin-only" do
    guardian = delegate.guardian
    expect(IsbfLearning.can_manage?(guardian)).to eq(true)
    expect(IsbfLearning.can_review?(guardian)).to eq(true)
    expect(IsbfLibrary.can_manage?(guardian)).to eq(false)
    expect(IsbfLibrary.can_review?(guardian)).to eq(false)
    admin_guardian = admin.guardian
    [IsbfLearning, IsbfLibrary].each do |library|
      expect(library.can_manage?(admin_guardian)).to eq(true)
      expect(library.can_review?(admin_guardian)).to eq(true)
    end
  end

  it "fails closed without academy methods and distinguishes management from review grants" do
    plain_guardian = Object.new
    plain_guardian.define_singleton_method(:is_admin?) { false }
    expect(IsbfLearning.can_manage?(plain_guardian)).to eq(false)
    expect(IsbfLearning.can_review?(plain_guardian)).to eq(false)
    plain_guardian.define_singleton_method(:academy_can?) do |permission|
      permission == :manage_resources
    end
    expect(IsbfLearning.can_manage?(plain_guardian)).to eq(true)
    expect(IsbfLearning.can_review?(plain_guardian)).to eq(false)
    expect(IsbfLibrary.can_manage?(plain_guardian)).to eq(false)
    expect(IsbfLibrary.can_review?(plain_guardian)).to eq(false)
  end

  it "preserves delegated course creation, metadata edits and deletion while denying library management" do
    learning = post_result(delegate, IsbfLearning)
    expect(learning.post).to be_present
    expect(learning.reviewable).to be_nil
    queued_library = post_result(delegate, IsbfLibrary)
    expect(queued_library.action).to eq(:enqueued)
    expect(queued_library.post).to be_nil
    library_post = post_result(admin, IsbfLibrary).post
    guardian = delegate.guardian
    expect(guardian.can_edit_post?(learning.post)).to eq(true)
    expect(guardian.can_delete_topic?(learning.post.topic)).to eq(true)
    expect(guardian.can_edit_post?(library_post)).to eq(false)
    expect(guardian.can_delete_topic?(library_post.topic)).to eq(false)
    sign_in(delegate)
    put "/posts/#{learning.post.id}.json",
        params: {
          title: "Delegated revised course reference",
          post: {
            raw: "Updated course reference https://example.org/revised-academy.pdf",
            isbf_learning_link: "https://example.org/revised-academy.pdf",
            isbf_learning_description: "Updated course description",
            isbf_learning_contributor: "课程小组",
          },
        }
    expect(response.status).to eq(200), response.body
    expect(learning.post.topic.reload.custom_fields).to include(
      IsbfLearning::COURSE_FIELD => course.fetch("id"),
      IsbfLearning::LINK_FIELD => "https://example.org/revised-academy.pdf",
      IsbfLearning::DESCRIPTION_FIELD => "Updated course description",
      IsbfLearning::CONTRIBUTOR_FIELD => "课程小组",
    )
    put "/posts/#{library_post.id}.json",
        params: {
          post: {
            raw: "Updated https://example.org/library.pdf",
          },
        }
    expect(response.status).to eq(403), response.body
    delete "/isbf/library/resources/#{library_post.topic_id}.json"
    expect(response.status).to eq(403), response.body
    expect(library_post.topic.reload.deleted_at).to be_nil
    delete "/isbf/learning/resources/#{learning.post.topic_id}.json"
    expect(response.status).to eq(200), response.body
    expect(Topic.with_deleted.find(learning.post.topic_id).deleted_at).to be_present
  end

  it "preserves delegated native course review while denying independent library review" do
    learning = post_result(member, IsbfLearning).reviewable
    library = post_result(member, IsbfLibrary).reviewable
    expect(learning).to be_pending
    expect(library).to be_pending
    # Simulate the separate academy plugin's native review visibility grant.
    [learning, library].each do |reviewable|
      reviewable.update_columns(reviewable_by_moderator: true)
    end
    guardian = delegate.guardian
    expect(
      Reviewable
        .viewable_by(delegate, preload: false)
        .where(id: [learning.id, library.id])
        .pluck(:id),
    ).to eq([learning.id])
    expect(learning.actions_for(guardian).has?(:approve_post)).to eq(true)
    expect(library.actions_for(guardian).has?(:approve_post)).to eq(false)
    expect { library.perform(delegate, :approve_post) }.to raise_error(Reviewable::InvalidAction)
    expect(library.reload).to be_pending
    approval = learning.perform(delegate, :approve_post)
    expect(approval.success?).to eq(true)
    expect(approval.created_post.user_id).to eq(member.id)
    expect(
      approval.created_post.topic.reload.custom_fields.fetch(IsbfLearning::COURSE_FIELD),
    ).to eq(course.fetch("id"))
    expect(library.reload).to be_pending
  end
end
