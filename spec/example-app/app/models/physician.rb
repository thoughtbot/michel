class Physician < ApplicationRecord
  has_many :physician_availabilities
  has_many :appointments
end
