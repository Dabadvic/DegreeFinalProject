class Query < ActiveRecord::Base
  
  attr_accessor :options

  belongs_to :user

  enum status: [:waiting, :processing, :finished]

  mount_uploader :queryfile, QueryFileUploader

  before_create :set_initial_status

  validates :user_id,     presence: true
  validates :description, presence: { message: "No puedes dejar la descripción en blanco" }
  validates :queryfile,   presence: { message: "Tienes que elegir un archivo" }

  # Sends an email when an query finishes its execution
  def send_finished_email
    QueryMailer.query_finished(self.user, self.id).deliver_now
  end

  private

  # Sets the initial status
  def set_initial_status
  	self.status = "waiting"
  end

end
