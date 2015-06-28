require 'active_record'
require 'yaml'

# Use Active Record because we are being lazy, but also just want to get shit
# done and not think about it right now.

ActiveRecord::Base.establish_connection(YAML::load(File.open('database.yml')))

module CowboyCoursesModels
  class Term < ActiveRecord::Base
    has_many :sections
  end

  class Subject < ActiveRecord::Base
    has_many :courses
  end

  class Course < ActiveRecord::Base
    belongs_to :subject
  end

  class Section < ActiveRecord::Base
    belongs_to :course
    belongs_to :term
    has_and_belongs_to_many :instructors
  end

  class Instructor < ActiveRecord::Base
    has_and_belongs_to_many :sections
  end
end
