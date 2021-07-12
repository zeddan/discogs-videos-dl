require "httparty"
require "byebug"
require "optparse"


def get(url)
  token = ENV["DISCOGS_TOKEN"]
  fail("No DISCOGS_TOKEN set") unless token
  JSON.parse(HTTParty.get(url + "?token=#{token}").to_s)
end

def get_label_releases(label_id)
  url = "https://api.discogs.com/labels/#{label_id}/releases"
  releases = get(url)["releases"]
  return releases if releases

  fail("No releases found for label #{label_id}")
end

def get_artist_releases(artist_id)
  url = "https://api.discogs.com/artists/#{artist_id}/releases"
  releases = get(url)["releases"]
  return releases if releases

  fail("No releases found for artist #{artist_id}")
end

def get_release(id)
  url = "https://api.discogs.com/releases/#{id}"
  release = get(url)
  return release if release["videos"]

  fail("No videos found for release #{id}")
end

def get_by_artist(id)
  releases = get_artist_releases(id)
  release_urls = releases.map { |r| r["resource_url"] }
  result = release_urls.map { |url| get(url) }
  videos = result.map { |r| r["videos"] }.reject(&:nil?).flatten.map { |v| v["uri"] }.uniq
  save("artist_#{id}_urls", videos)
end

def get_by_label(id)
  releases = get_label_releases(id)
  release_urls = releases.map { |r| r["resource_url"] }
  result = release_urls.map { |url| get(url) }
  videos = result.map { |r| r["videos"] }.reject(&:nil?).flatten.map { |v| v["uri"] }.uniq
  save("label_#{id}_urls", videos)
end

def get_by_release(id)
  release = get_release(id)
  videos = release["videos"].map { |v| v["uri"] }
  save("release_#{id}_urls", videos)
end

def save(filename, urls)
  File.open(filename, "w") { |f| f.write(urls.join("\n")) }
  puts "#{urls.size} urls saved in #{filename}"
end

def fail(message)
  puts message
  exit 1
end

OptionParser.new do |opt|
  opt.on("-a", "--artist ARTIST_ID") { |id| get_by_artist(id) }
  opt.on("-l", "--label LABEL_ID") { |id| get_by_label(id) }
  opt.on("-r", "--release RELEASE_ID") { |id| get_by_release(id) }
end.parse!

