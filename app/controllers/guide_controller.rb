class GuideController < ApplicationController
  allow_unauthenticated_access only: %i[index solid_trio]

  def index
  end

  def solid_trio
  end
end
