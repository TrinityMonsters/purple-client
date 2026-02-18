require 'purple/client'

module TimeMagic
  class Client < Purple::Client
    path :api do
      draw 'clients/v1'
    end
  end
end
