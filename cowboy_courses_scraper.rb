require 'mechanize'
require 'date'

module CowboyCoursesScraper
  class Term
    attr_accessor :id, :name
  end

  class Subject
    attr_accessor :id, :name
  end

  class Course
    attr_accessor :id, :name, :subject_id
  end

  class Section
    attr_accessor :id, :name, :call_number, :status, :open_seats, :total_seats, :days, :instructors, :course_id, :term_id, :starts_at, :ends_at, :starts_on, :ends_on
  end

  class CowboyCoursesScraper
    URL = 'http://prodosu.okstate.edu/osup-bin/tsrvweb.exe?&WID=W&tserve_tip_write=||WID&ConfigName=rclssecttrms2osu&ReqNum=1&TransactionSource=H&tserve_trans_config=rclssecttrms2osu.cfg&tserve_host_code=HostSeventeen&tserve_tiphost_code=TipSeventeen'
  end

  # Scrape the terms.
  class TermsScraper < CowboyCoursesScraper
    def scrape
      agent = Mechanize.new
      terms_page = agent.get(URL)
      return parse_terms(terms_page)
    end

    def parse_terms(terms_page)
      terms = []
      terms_form = terms_page.form('StuForm')
      terms_form.field_with(:name => 'Term').options.each do |option|
        id = option.value.strip
        name = option.text.strip
        next if name.empty? || id.empty?
        term = Term.new
        term.id = id
        term.name = name
        terms << term
      end
      return terms
    end
  end

  # Scrape all the subjects for a given term.
  class SubjectsScraper < CowboyCoursesScraper
    def scrape(term_id)
      agent = Mechanize.new
      terms_page = agent.get(URL)
      terms_form = terms_page.form('StuForm')
      terms_form['Term'] = term_id
      subjects_page = terms_form.submit
      return parse_subjects(subjects_page)
    end

    def parse_subjects(subjects_page)
      subjects = []
      subjects_form = subjects_page.form('StuForm')
      subjects_form.field_with(:name => 'Subject').options.each do |option|
        name = option.text.strip
        id = option.value.strip
        next if name.empty? || id.empty?
        subject = Subject.new
        subject.id = id
        subject.name = name
        subjects << subject
      end
      return subjects
    end
  end

  class CoursesScraper < CowboyCoursesScraper
    def scrape(term_id, subject_id)
      agent = Mechanize.new
      terms_page = agent.get(URL)
      terms_form = terms_page.form('StuForm')
      terms_form['Term'] = term_id
      subjects_page = terms_form.submit
      subjects_form = subjects_page.form('StuForm')
      subjects_form['Subject'] = subject_id
      courses_page = subjects_form.submit
      return parse_courses(courses_page, term_id, subject_id)
    end

    def parse_courses(courses_page, term_id, subject_id)
      courses = []

      # NOTE: The options are loaded from JavaScript on this page and are in
      # hidden field on the page. Here we are getting the hidden field where
      # all the options are stored in the value attribute and parsing them out.
      # Otherwise we need to load this page using JavaScript support.
      hidden_field_id = %Q{#{subject_id}#{term_id}HTM}
      hidden_fields = courses_page.search(%Q{//input[@id="#{hidden_field_id}"]})

      hidden_fields.each do |hidden_field|
        options = hidden_field['value'].scan(/value='(.+)'.*>(.+)</i)
        options.each do |option|
          id = option[0].gsub(/\s+/, '')
          name = option.length > 1 ? option[1].strip : id
          course = Course.new
          course.subject_id = subject_id
          course.name = name
          course.id = id
          courses << course
        end
      end
      return courses
    end
  end

  class SectionsScraper < CowboyCoursesScraper
    def scrape(term_id, subject_id, course_id)
      agent = Mechanize.new

      terms_page = agent.get(URL)
      terms_form = terms_page.form('StuForm')
      terms_form['Term'] = term_id

      subjects_page = terms_form.submit
      subjects_form = subjects_page.form('StuForm')
      subjects_form['Subject'] = subject_id

      # The options are loaded with JavaScript on this page.
      courses_page = subjects_form.submit
      courses_form = courses_page.form('courselist')

      fixed_course_id = fix_course_id(course_id)
      courses_form['CourseID'] = fixed_course_id
      courses_form['Status'] = 'A' # All sections radio button.

      sections_page = courses_form.submit
      return parse_sections(sections_page, term_id, course_id)
    end

    def fix_course_id(id)
      parts = id.split('-')
      return sprintf('%-4s-%s', parts[0], parts[1])
    end

    def parse_sections(sections_page, term_id, course_id)
      sections = []
      trs = sections_page.search('table.tablecrs tr')
      trs.each do |tr|
        section = Section.new
        section.term_id = term_id
        section.course_id = course_id
        section.instructors = []

        tds = tr.search('td')
        tds.each do |td|
          if td['headers'] == 'CourseID'
            if td.inner_text =~ /([ a-z]+-[ 0-9]+-[0-9]+)\s*(.*)/im
              section.id = $1.gsub(/\s+/, '')
              if !$2.nil? && !$2.empty?
                section.name = $2.strip
              else
                # Set the name to the course id as an alternative.
                section.name = section.id
              end
            end
          elsif td['headers'] == 'CallNumber'
            section.call_number = td.text.gsub(/[^0-9]/, '')
          elsif td['headers'] == 'StatusAndSeats'
            if td.text =~ /open[^0-9]*([0-9]+)[^0-9]*([0-9]+)/im
              section.status = 'open'
              section.open_seats = $1 if !$1.nil? && !$1.empty?
              section.total_seats = $2 if !$2.nil? && !$2.empty?
            elsif td.text =~ /unlimited/im
              section.status = 'unlimited'
            else
              section.status = td.text.strip.downcase
            end
          elsif td['headers'] == 'DaysTimeLocation'
            if td.text =~ /([a-z]+)[^0-9]*(([0-9]+):([0-9]+)([a-z]*))\s*-\s*(([0-9]+):([0-9]+)([a-z]*))/im
              # $1 => days
              # $2 => start time
              # $3 => start hour
              # $4 => start minutes
              # $5 => start am/pm
              # $6 => end time
              # $7 => end hour
              # $8 => end minutes
              # $9 => end am/pm
              # 11:30 - 1:30PM => 11:30 - 13:30
              # 7:00 - 8:00PM => 07:00 - 20:00 (incorrect)
              # 7:00 - 8:00AM => 07:00 - 08:00
              section.starts_at = Time.parse($2)
              section.ends_at = Time.parse($6)
              section.starts_at = section.starts_at + (12 * 60 * 60) if section.ends_at.hour > 12 && (section.ends_at.hour - 12) > section.starts_at.hour
              section.days = $1.gsub(/\s+/, '')
            else
              # Most likely: "To Be Arranged"
            end
          elsif td['headers'] == 'Instructor'
            td.search('br').each do |n|
              n.replace("\n")
            end
            section.instructors += td.text.split("\n").map { |n| n.strip }.reject { |i| i.empty? }
          elsif td['headers'] == 'Session'
            ds = td.text.gsub(/[^0-9]/, '')
            if ds.length == 12
              m1 = ds[0, 2].to_i
              d1 = ds[2, 2].to_i
              y1 = ds[4, 2].to_i + 2000
              section.starts_on = DateTime.new(y1, m1, d1)
              
              m2 = ds[6, 2].to_i
              d2 = ds[8, 2].to_i
              y2 = ds[10, 2].to_i + 2000
              section.ends_on = DateTime.new(y2, m2, d2)
            end
          end
          # TODO: Credits
          # TODO: Prerequisites with links
          # TODO: Notes with links to sections / courses
          # TODO: Name (displayed after the Courseid)
          # TODO: Location so we can show a map view on mobile device.
        end

        if !section.id.nil? && !section.id.empty?
          # section = Section.new(id, name, call_number, status, open_seats, total_seats, days, starts_on, starts_at, ends_on, ends_at, instructors, course_id, term_id)
          sections << section
        end
      end
      return sections
    end
  end
end
