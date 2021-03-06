# encoding: utf-8

require_relative '../utils'
require_relative 'language'

module RecastAI
  class Expression
    attr_accessor :id, :source, :tokens, :language
    attr_accessor :intent

    def initialize(response = nil, intent = nil)
      @intent = intent
      @raw = response

      if response
        @id = response['id']
        @source = response['source']
        @tokens = response['tokens']
        @language = RecastAI::Language.new response['language']
      end
    end

    def as_json(options = {})
      data = {
        source: source,
        language: language.as_json,
        tokens: tokens
      }
      data[:id] = id if id

      data
    end

    def to_json(*a)
      as_json.to_json
    end

    def save!
      response = HTTParty.put(
        Utils::endpoint(@intent.bot.user_slug, @intent.bot.slug, Utils::INTENTS_SUFFIX, @intent.slug, Utils::EXPRESSIONS_SUFFIX, self.id),
        headers: {
          'Authorization' => "Token #{@intent.bot.developer_token}",
          'Content-Type'  => 'application/json'
        },
        body: self.to_json
      )
      RecastError::raise_if_error response

      # Return a fresh expression (eg. with tokens)
      return Expression.new JSON.parse(response.body)['results'], self.intent
    end

    def delete!
      response = HTTParty.delete(
        Utils::endpoint(@intent.bot.user_slug, @intent.bot.slug, Utils::INTENTS_SUFFIX, @intent.slug, Utils::EXPRESSIONS_SUFFIX, self.id),
        headers: {
          'Authorization' => "Token #{@intent.bot.developer_token}"
        }
      )
      RecastError::raise_if_error response, 200
    end
  end
end
