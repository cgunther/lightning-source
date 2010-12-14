module LightningSource
  class Base
    
  private
    
    def parse_numeric(string)
      string.to_i
    end
    
    def parse_date(string)
      Date.parse(string)
    end
    
    def parse_time(string)
      string.gsub(/(\d{2})(\d{2})(\d{2})/, '\1:\2:\3')
    end
    
    def parse_string(string)
      string.strip
    end
    
  end
end
