module Twurl
  module RequestTracing
    def self.included(klass)
      {:> => [:write, :writeline],
       :< => [:read, :read_all, :readuntil]}.each do |tracing_prefix, methods|
        methods.each do |method|
          klass.class_eval(<<-EVAL, __FILE__, __LINE__)
            def #{method}_with_tracing(*args)
              result = #{method}_without_tracing(*args)
              trace("#{tracing_prefix} \#{result}")
              result
            end
            alias_method :#{method}_without_tracing, :#{method}
            alias_method :#{method}, :#{method}_with_tracing
          EVAL
        end
      end
    end

    def trace(line)
      iostream.write(line)
    end

    private
      def iostream
        STDERR
      end
  end
end

class Net::BufferedIO
  include Twurl::RequestTracing
end