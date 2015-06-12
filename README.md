# Cowboy Courses Scraper

It scrapes the Oklahoma State University [courses catalog] (http://prodosu.okstate.edu/osup-bin/tsrvweb.exe?&WID=W&tserve_tip_write=||WID&ConfigName=rclssecttrms2osu&ReqNum=1&TransactionSource=H&tserve_trans_config=rclssecttrms2osu.cfg&tserve_host_code=HostSeventeen&tserve_tiphost_code=TipSeventeen).


It's used in a little app I am currently working on that will track and notify a user about certain status changes and updates via SMS and/or email.


Each scraper returns a plain old Ruby object with the known scraped properties.


Here is a quick example usage.

```ruby

require './cowboy_courses_scraper'

# Get all the current terms.
terms = CowboyCoursesScraper::TermsScraper.new.scrape
term = term[0]
puts term.name

# Get the subjects for a term.
subjects = CowboyCoursesScraper::SubjectsScraper.new.scrape(term)
subject = subjects[0]
puts subject.name

# Courses for a term and subject.
courses = CowboyCoursesScraper::CoursesScraper.new.scrape(subject)
course = courses[0]
puts course.name

# Finally, get the stuff that actually matters.
# Sections for a course for a term.
sections = CowboyCoursesScraper::SectionsScraper.new.scrape(course)
section = section[0]
puts section.name
puts section.status
puts section.starts_at
puts section.ends_at
puts sections.instructors
puts sections.open_seats

```