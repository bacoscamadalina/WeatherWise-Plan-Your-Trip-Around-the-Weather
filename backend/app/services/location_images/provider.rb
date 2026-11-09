module LocationImages
  Result = Data.define(:image_url, :attribution, :source_url, :provider)

  class Provider
    def fetch(location:, language: "en")
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end
  end
end
