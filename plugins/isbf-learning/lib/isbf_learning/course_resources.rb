# frozen_string_literal: true

module IsbfLearning
  module CourseResourceSubmission
    def enqueue(reason = nil, creator_opts: {})
      return super if args[:topic_id].present?
      unless args[COURSE_FIELD.to_sym].present? ||
               IsbfLearning.resource_library_for_category(args[:category]) == IsbfLearning
        return super
      end

      Courses.with_catalog_lock do
        IsbfLearning.validate_payload!(user, args)
        super
      end
    end
  end

  module CourseResourceCreation
    private

    def transaction(&block)
      return super if opts[:topic_id].present?
      unless opts[COURSE_FIELD.to_sym].present? ||
               IsbfLearning.resource_library_for_category(opts[:category]) == IsbfLearning
        return super
      end

      super { Courses.with_catalog_lock(&block) }
    end
  end

  module CourseResourceRevision
    def revise!(editor, fields, opts = {}, &block)
      return super unless @post.is_first_post?
      unless IsbfLearning.learning_topic?(@post.topic) || fields[COURSE_FIELD.to_sym].present?
        return super
      end

      Courses.with_catalog_lock { super }
    end
  end

  module CourseResourceReview
    def perform(performed_by, action_id, args = nil)
      unless payload&.[](COURSE_FIELD).present? || category_id == IsbfLearning.category_id
        return super
      end

      Courses.with_catalog_lock { super }
    end

    def perform_approve_post(performed_by, args)
      result = super
      if payload&.[](COURSE_FIELD).present? && result&.after_commit
        callback = result.after_commit
        # The catalog lock keeps an outer transaction open through the native action.
        result.after_commit = -> { DB.after_commit(&callback) }
      end
      result
    end
  end
end
