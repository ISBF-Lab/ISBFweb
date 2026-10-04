# frozen_string_literal: true

module IsbfModeration
  module ReviewQueue
    def self.prioritize(relation)
      severe = "reviewables.payload ->> '#{Hold::PENDING}' = 'true'"
      relation.reorder(
        Arel.sql("CASE WHEN #{severe} THEN 0 ELSE 1 END ASC"),
        Arel.sql(
          "CASE WHEN #{severe} THEN reviewables.payload ->> '#{Hold::LATEST}' END DESC NULLS LAST",
        ),
        *relation.order_values,
      )
    end

    def list_for(user, **options)
      if options.fetch(:status, :pending) == :pending
        options[:additional_filters] = (options[:additional_filters] || {}).merge(
          isbf_severe_priority: true,
        )
      end
      super(user, **options)
    end
  end
end
