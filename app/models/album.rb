class Album < ApplicationRecord
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :genres
  belongs_to :user
end
