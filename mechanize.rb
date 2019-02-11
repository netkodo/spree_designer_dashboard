require "net/http"
# require 'mechanize'
@failed_links = []

fero.each{|x| test(x)}

def test(url)

  f = URI.parse(url[1])
  req = Net::HTTP.new(f.host, f.port)
  req.use_ssl = true
  res = req.request_head(f.path)
  @failed_links << [f, url[0]] unless res.code == "200"
end