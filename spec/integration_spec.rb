require "net/http"
require "open3"
require "irb"
UUID_PATTERN = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

RSpec.describe "Integration test" do
  let(:port) do
    ENV.fetch("PORT").to_i
  end

  let(:uri) do
    URI::HTTP.build(host: "localhost", port: port)
  end

  describe "POST /" do
    it "responds with 201 and the post ID" do
      Net::HTTP.start(uri.host, uri.port) do |http|
        uri.path = "/"
        request = Net::HTTP::Post.new(uri)
        request.body = "Hello, world!\n"
        request.content_type = "text/plain; charset=utf-8"

        response = http.request(request)

        expect(response.code).to eql "201"
        expect(response["Content-Type"]).to eql "text/plain; charset=utf-8"

        expect(response.body).to match(/\Ahttp:\/\/localhost:#{port}\/#{UUID_PATTERN}\z/)
      end
    end
  end

  describe "GET /:post_id" do
    context "given a valid post ID" do
      it "responds with 200 and the post body" do
        Net::HTTP.start(uri.host, uri.port) do |http|
          uri.path = "/"
          request = Net::HTTP::Post.new(uri)
          request.body = "Hello, world!\n"
          request.content_type = "text/plain; charset=utf-8"
          response = http.request(request)

          request = Net::HTTP::Get.new(URI(response.body))

          response = http.request(request)

          expect(response.code).to eql "200"
          expect(response["Content-Type"]).to eql "text/plain; charset=utf-8"
          expect(response.body).to eql "Hello, world!\n"
        end
      end
    end

    context "given an invalid post ID" do
      it "responds with 404" do
        Net::HTTP.start(uri.host, uri.port) do |http|
          uri.path = "/foobar"
          request = Net::HTTP::Get.new(uri)

          response = http.request(request)

          expect(response.code).to eql "404"
          expect(response["Content-Type"]).to eql "text/plain; charset=utf-8"
          expect(response.body).to eql "Not found\n"
        end
      end
    end
  end
end
