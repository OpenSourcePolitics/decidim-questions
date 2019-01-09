# frozen_string_literal: true

Decidim::CellsHelper.module_eval do

  def questions_controller?
    context[:controller].class.to_s == "Decidim::Questions::QuestionsController"
  end

  def withdrawable?
    return unless from_context
    return unless proposals_controller? || questions_controller?
    return if index_action?
    from_context.withdrawable_by?(current_user)
  end

  def flagable?
    return unless from_context
    return unless proposals_controller? || collaborative_drafts_controller? || questions_controller?
    return if index_action?
    return if from_context.try(:official?)
    true
  end
end
