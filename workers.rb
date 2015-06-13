require 'resque'
require './cowboy_courses_scraper'

class TermsScraperJob
  include CowboyCoursesScraper

  @queue = :terms_scraper

  def self.perform
    terms = TermsScraper.new.scrape
    terms.each do |t|
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
      Resque.enqueue(SectionsScraperJob, term_id, subject_id, c.id)
    end
  end
end

class SectionsScraperJob
  include CowboyCoursesScraper

  @queue = :sections_scraper

  def self.perform(term_id, subject_id, course_id)
    sections = SectionsScraper.new.scrape(term_id, subject_id, course_id)
    sections.each do |section|
      puts "Scraped sections for #{term_id} -> #{subject_id} -> #{course_id}"
    end
  end
end
