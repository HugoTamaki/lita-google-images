require "lita"

require "multi_json"
require "faraday"

module Lita
  module Handlers
    class GoogleImages < Handler
      URL = "https://ajax.googleapis.com/ajax/services/search/images"

      route(/(?:image|img)(?:\s+me)? (.+)/, to: :fetch, command: true, help: {
        "image QUERY" => "Displays a random image from Google Images matching the query."
      })

      def fetch(matches)
        query = matches[0][0]

        response = Faraday.get(
          URL,
          v: "1.0",
          q: query,
          safe: safe_value,
          rsz: 8
        )

        data = MultiJson.load(response.body)

        if data["responseStatus"] == 200
          choice = data["responseData"]["results"].sample
          reply "#{choice["unescapedUrl"]}#.png"
        else
          reason = data["responseDetails"] || "unknown error"
          Lita.logger.warn(
            "Couldn't get image from Google: #{reason}"
          )
        end
      end

      private

      def safe_value
        safe = Lita.config.handlers.google_images.safe_search || "active"
        safe = safe.to_s.downcase
        safe = "active" unless ["active", "moderate", "off"].include?(safe)
        safe
      end
    end

    Lita.config.handlers.google_images = Config.new
    Lita.config.handlers.google_images.safe_search = :active
    Lita.register_handler(GoogleImages)
  end
end