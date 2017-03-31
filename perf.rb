require "benchmark/ips"
require "net/http"

def run(port, times)
  uri = URI::HTTP.build(host: "localhost", port: port)
  Net::HTTP.start(uri.host, uri.port) do |http|
    post_uri = uri.dup
    post_uri.path = "/"

    post_request = Net::HTTP::Post.new(post_uri)
    post_request.body = "Hello, world!\n"
    post_request.content_type = "text/plain; charset=utf-8"

    times.times do
      response = http.request(post_request)
      post_id = response.body

      get_uri = uri.dup
      get_uri.path = "/#{post_id}"
      get_request = Net::HTTP::Get.new(get_uri)

      response = http.request(get_request)
    end
  end
end

Benchmark.ips do |x|
  x.report("3000") do |times|
    run(3000, times)
  end

  x.report("3001") do |times|
    run(3001, times)
  end

  x.report("3002") do |times|
    run(3002, times)
  end
end
