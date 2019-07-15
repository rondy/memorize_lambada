require 'rspec'
require 'byebug'

describe do
  it 'regular/before version' do
    revision_result = BlogPostRevisor.new(
      entry_title: 'Ten Years of Elaine',
      entry_url: 'https://ferd.ca/ten-years-of-erlang.html'
    ).revise

    expect(revision_result).to eq({
      matched: false,
      given_entry_title: 'Ten Years of Elaine',
      fetched_page_title: 'Ten Years of Erlang'
    })
  end

  it 'pragmatic after version' do
    revision_result = ReviseBlogPosts.new.call(
      entry_title: 'Ten Years of Elaine',
      entry_url: 'https://ferd.ca/ten-years-of-erlang.html'
    )

    expect(revision_result).to eq({
      matched: false,
      given_entry_title: 'Ten Years of Elaine',
      fetched_page_title: 'Ten Years of Erlang'
    })
  end

  it 'pragmatic after version with mock' do
    revision_result = ReviseBlogPosts.new(
      fetch_page_title: lambda do |entry_url| 'Ten Years of Erlang' end
    )
    .call(
      entry_title: 'Ten Years of Elaine',
      entry_url: 'https://ferd.ca/ten-years-of-erlang.html'
    )

    expect(revision_result).to eq({
      matched: false,
      given_entry_title: 'Ten Years of Elaine',
      fetched_page_title: 'Ten Years of Erlang'
    })
  end

  it 'astronautic after version' do
    revision_result = AstronauticReviseBlogPosts.new
    .call(
      entry_title: 'Ten Years of Elaine',
      entry_url: 'https://ferd.ca/ten-years-of-erlang.html'
    )

    expect(revision_result).to eq({
      matched: false,
      given_entry_title: 'Ten Years of Elaine',
      fetched_page_title: 'Ten Years of Erlang'
    })
  end
end

require 'mechanize'

class BlogPostRevisor # => ?
  def initialize(entry_title:, entry_url:)
    @entry_title = entry_title
    @entry_url = entry_url
  end

  def revise # => ?
    # => ?
    page_title_matches = check_titles_match(fetched_page_title)

    {
      matched: page_title_matches,
      given_entry_title: entry_title,
      fetched_page_title: fetched_page_title
    }
  end

  private

  attr_reader :entry_title, :entry_url

  # impure
  def fetched_page_title
    @fetched_page_title ||= begin
      agent = Mechanize.new
      agent.read_timeout = 2
      page = agent.get(entry_url)
      page.title
    end
  end

  # pure
  def check_titles_match(fetched_title)
    given_title_as_regexp = Regexp.new(Regexp.escape(entry_title), Regexp::IGNORECASE)

    !!(fetched_title =~ given_title_as_regexp)
  end
end


class ReviseBlogPosts
  def initialize(fetch_page_title: nil)
    @fetch_page_title = fetch_page_title
  end

  # primitive obsession
  # data clump
  def call(entry_title:, entry_url:)
    given_entry_title = entry_title
    fetched_page_title = fetch_page_title.call(entry_url)
    page_title_matches = check_titles_match(given_entry_title, fetched_page_title)

    {
      matched: page_title_matches,
      given_entry_title: entry_title,
      fetched_page_title: fetched_page_title
    }
  end

  private

  def fetch_page_title
    @fetch_page_title ||= begin
      lambda do |entry_url|
        FetchPageTile.new.call(entry_url)
      end
    end
  end

  def check_titles_match(given_title, fetched_title)
    given_title_as_regexp = Regexp.new(Regexp.escape(given_title), Regexp::IGNORECASE)

    !!(fetched_title =~ given_title_as_regexp)
  end
end

class AstronauticReviseBlogPosts
  def initialize(fetch_page_title: nil)
    @fetch_page_title = fetch_page_title
  end

  def call(raw_entry) # =? entry
    entry = Entry(raw_entry)
    fetched_page_title = fetch_page_title.call(entry.url)
    page_title_matches = entry.matchable.title_matches?(fetched_page_title)

    {
      matched: page_title_matches,
      given_entry_title: entry.title,
      fetched_page_title: fetched_page_title
    }
  end

  private

  def fetch_page_title
    @fetch_page_title ||= begin
      lambda do |entry_url|
        FetchPageTile.new.call(entry_url)
      end
    end
  end

  def check_titles_match(given_title, fetched_title)
    given_title_as_regexp = Regexp.new(Regexp.escape(given_title), Regexp::IGNORECASE)

    !!(fetched_title =~ given_title_as_regexp)
  end
end

class Entry
  attr_reader :title, :url

  def initialize(entry)
    @title = entry.fetch(:entry_title)
    @url = entry.fetch(:entry_url)
  end

  def matchable
    MatchableEntry.new(self)
  end
end

def Entry(entry)
  case entry
  when Hash then Entry.new(entry)
  when Entry then entry
  else fail TypeError
  end
end

class MatchableEntry
  def initialize(entry)
    @entry = entry
  end

  def title_matches?(other_title)
    title_as_regexp = Regexp.new(Regexp.escape(@entry.title), Regexp::IGNORECASE)

    !!(other_title =~ title_as_regexp)
  end
end

class FetchPageTile
  def call(entry_url)
    agent = Mechanize.new
    agent.read_timeout = 2
    page = agent.get(entry_url)
    page.title
  end
end
