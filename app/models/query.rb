class Query < ActiveRecord::Base
  belongs_to :user

  enum status: [:waiting, :processing, :finished]

  mount_uploader :queryfile, QueryFileUploader

  before_save :set_initial_status

  validates :user_id, presence: true
  validates :description, presence: true
  validates :queryfile, presence: true

  private

  # Sets the initial status
  def set_initial_status
  	self.status = "waiting"
  end

end
