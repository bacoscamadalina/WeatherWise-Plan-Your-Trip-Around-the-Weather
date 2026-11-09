module LocationImages
  class NullProvider < Provider
    def fetch(location:, language: "en")
      nil
    end
  end
end
