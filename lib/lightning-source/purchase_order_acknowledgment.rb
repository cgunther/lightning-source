module LightningSource
  class PurchaseOrderAcknowledgment
    
    def self.fetch(opts)
      require 'net/ftp'
      require 'tempfile'
      
      ftp = Net::FTP.new(opts[:host], opts[:username], opts[:password])
      ftp.chdir('outgoing')
      ftp.list('*.PPR').compact.map do |file|
        filename = file.split[-1]
        tempfile = Tempfile.new(filename)
        ftp.gettextfile(filename, tempfile.path)
        PurchaseOrderAcknowledgment.new(tempfile)
      end
    end
    
    def initialize(raw_data)
      @raw_data = raw_data.read
    end
    
  end
end
