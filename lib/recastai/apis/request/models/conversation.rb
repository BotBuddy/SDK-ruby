# encoding: utf-8

require_relative 'action'
require_relative 'entity'
require_relative 'intent'
require_relative '../utils'

module RecastAI
  class Conversation
    attr_reader :raw, :uuid, :source, :replies, :action, :next_actions, :memory, :entities, :sentiment, :intents,
                :conversation_token, :language, :processing_language, :version, :timestamp, :status

    def initialize(response, token)
      @token = token

      @raw = response

      response = JSON.parse(response)
      response = response['results']

      @uuid                = response['uuid']
      @source              = response['source']
      @replies             = response['replies']
      @action              = response['action'] ? Action.new(response['action']) : nil
      @next_actions        = response['next_actions'].map{ |i| Action.new(i) }
      @sentiment           = response['sentiment']
      @memory              = response['memory'].reject{ |_, e| e.nil? }.map{ |n, e| Entity.new(n, e) }
      @entities            = response['entities'].flat_map{ |n, e| e.map{ |ee| Entity.new(n, ee) } }
      @intents             = response['intents'].map{ |i| Intent.new(i) }
      @conversation_token  = response['conversation_token']
      @language            = response['language']
      @processing_language = response['processing_language']
      @version             = response['version']
      @timestamp           = response['timestamp']
      @status              = response['status']
    end

    def reply
      @replies.any? ? @replies.first : nil
    end

    def next_action
      @next_actions.any? ? @next_actions.first : nil
    end

    def joined_replies(sep = ' ')
      @replies.join(sep)
    end

    def get_memory(key = nil)
      return @memory if key.nil?

      @memory.each do |entity|
        return entity if entity.name.casecmp(key.to_s).zero?
      end

      nil
    end

    def intent
      @intents.any? ? @intents.first : nil
    end

    def vpositive?
      @sentiment == Utils::SENTIMENT_VPOSITIVE
    end

    def positive?
      @sentiment == Utils::SENTIMENT_POSITIVE
    end

    def neutral?
      @sentiment == Utils::SENTIMENT_NEUTRAL
    end

    def negative?
      @sentiment == Utils::SENTIMENT_NEGATIVE
    end

    def vnegative?
      @sentiment == Utils::SENTIMENT_VNEGATIVE
    end

    def set_memory(memory)
      body = { conversation_token: @conversation_token, memory: memory }
      response = HTTParty.put(
        Utils::CONVERSE_ENDPOINT,
        body: body,
        headers: { 'Authorization' => "Token #{@token}" }
      )
      raise RecastError.new(JSON.parse(response.body)['message']) if response.code != 200

      response = JSON.parse(response.body)
      response = response['results']
      response['memory'].reject{ |_, e| e.nil? }.map{ |n, e| Entity.new(n, e) }
    end

    def reset_memory(name = nil)
      body = { conversation_token: @conversation_token }
      body[:memory] = { name => nil } unless name.nil?

      response = HTTParty.put(
        Utils::CONVERSE_ENDPOINT,
        body: body,
        headers: { 'Authorization' => "Token #{@token}" }
      )
      raise RecastError.new(JSON.parse(response.body)['message']) if response.code != 200

      response = JSON.parse(response.body)
      response = response['results']
      response['memory'].reject{ |_, e| e.nil? }.map{ |n, e| Entity.new(n, e) }
    end

    def reset_conversation
      body = { conversation_token: @conversation_token }
      response = HTTParty.delete(
        Utils::CONVERSE_ENDPOINT,
        body: body,
        headers: { 'Authorization' => "Token #{@token}" }
      )
      raise RecastError.new(JSON.parse(response.body)['message']) if response.code != 200

      response = JSON.parse(response.body)
      response = response['results']
      response['memory'].reject{ |_, e| e.nil? }.map{ |n, e| Entity.new(n, e) }
    end
  end
end
