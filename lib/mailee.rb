module Mailee
  class Config < ActiveResource::Base
    # O self.site tem q ser configurado no environment!
  end
  class Contact < Config
  end
  class List < Config
  end
end

