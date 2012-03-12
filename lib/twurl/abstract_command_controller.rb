module Twurl
  # Subclasses need to implement a `dispatch' instance method.
  class AbstractCommandController
    attr_reader :client, :options
    class << self
      def dispatch(*args, &block)
        new(*args, &block).dispatch
      end
    end

    def initialize(client, options)
      @client  = client
      @options = options
    end
  end
end
