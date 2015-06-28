require 'resque'
require './cowboy_courses_scraper'
require './models'

class TermsScraperJob
  include CowboyCoursesScraper

  @queue = :terms_scraper

  def self.perform
    terms = TermsScraper.new.scrape
    terms.each do |t|
      term = CowboyCoursesModels::Term.find_or_initialize_by(scraped_id: t.id)
      term.name = t.name
      term.save!

      Resque.enqueue(SubjectsScraperJob, t.id)
    end
  end
end

class SubjectsScraperJob
  include CowboyCoursesScraper

  @queue = :subjects_scraper

  def self.perform(term_id)
    subjects = SubjectsScraper.new.scrape(term_id)
    subjects.each do |s|
      subject = CowboyCoursesModels::Subject.find_or_initialize_by(scraped_id: s.id)
      subject.name = s.name
      subject.save!
      Resque.enqueue(CoursesScraperJob, term_id, s.id)
    end
  end
end

class CoursesScraperJob
  include CowboyCoursesScraper

  @queue = :courses_scraper

  def self.perform(term_id, subject_id)
    # This will return all the courses scraped.
    courses = CoursesScraper.new.scrape(term_id, subject_id)
    courses.each do |c|
      subject = CowboyCoursesModels::Subject.find_by(scraped_id: subject_id)
      course = CowboyCoursesModels::Course.find_or_initialize_by(scraped_id: c.id)
      course.name = c.name
      course.subject = subject
      course.save!

      Resque.enqueue(SectionsScraperJob, term_id, subject_id, c.id)
    end
  end
end

class SectionsScraperJob
  include CowboyCoursesScraper

  @queue = :sections_scraper

  def self.perform(term_id, subject_id, course_id)
    sections = SectionsScraper.new.scrape(term_id, subject_id, course_id)
    sections.each do |s|
      term = CowboyCoursesModels::Term.find_by(scraped_id: s.term_id)
      course = CowboyCoursesModels::Course.find_by(scraped_id: s.course_id)
      section = CowboyCoursesModels::Section.find_or_initialize_by(term: term, course: course, scraped_id: s.id)
      section.name = s.name
      section.call_number = s.call_number
      section.status = s.status
      section.open_seats = s.open_seats
      section.total_seats = s.total_seats
      section.days = s.days
      section.starts_at = s.starts_at
      section.starts_on = s.ends_at
      section.ends_at = s.ends_at
      section.ends_on = s.ends_on
      s.instructors.each do |i|

        instructor = CowboyCoursesModels::Instructor.find_or_initialize_by(name: i)
        section.instructors << instructor unless section.instructors.exists?(instructor.id)
        instructor.save!
      end
      section.save!
    end
  end
end
