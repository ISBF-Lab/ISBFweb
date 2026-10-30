# frozen_string_literal: true

module IsbfMbti
  class QuestionnairesController < BaseController
    requires_login only: %i[show]

    def index
      render json: {
               questionnaires:
                 Questionnaire::VARIANTS.map { |variant| Questionnaire.fetch(variant).metadata },
             }
    end

    def show
      render json: { questionnaire: Questionnaire.fetch(params[:id]).definition }
    end
  end
end
