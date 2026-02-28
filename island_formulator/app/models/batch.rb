class Batch < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :made_on, presence: true
end
