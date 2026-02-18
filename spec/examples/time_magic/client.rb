require 'purple/client'

module TimeMagic
  class Client < Purple::Client
    draw 'clients/v1'
  end
end
