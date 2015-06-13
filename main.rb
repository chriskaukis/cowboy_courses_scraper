require 'resque'
require './workers'

def scrape_async
  Resque.enqueue(TermsScraperJob)
end

def main(args)
  scrape_async
end

main(ARGV) if __FILE__ == $0