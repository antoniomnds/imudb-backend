# frozen_string_literal: true

module Api
  class OpenaiClient < Client
    class << self
      def send_prompt(prompt)
        new.create_completion(prompt)
      end
    end

    attr_reader :api_key

    def initialize
      @api_key = ENV["OPENAI_API_KEY"]
    end

    def create_completion(prompt)
      base_url = URI("https://api.openai.com/v1/chat/completions")
      headers = {
        "Authorization": "Bearer #{ api_key }",
        "Content-type": "application/json"
      }
      data = %Q({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful assistant."
          },
          {
            "role": "user",
            "content": "#{ prompt }"
          }
        ]
      })
      response = Net::HTTP.post(base_url, data, headers)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        data.dig("choices", 0, "message", "content")
      else
        log_response("Failed to get completion", response, :error)
      end
    end
  end
end
