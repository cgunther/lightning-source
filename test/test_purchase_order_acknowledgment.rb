require 'helper'
require 'net/ftp'
require 'tempfile'

class TestPurchaseOrderAcknowledgment < Test::Unit::TestCase
  
  context "PurchaseOrderAcknowledgment.fetch" do
    
    should "return empty array if no POA's exist" do
      ftp = mock 'ftp' do
        expects(:chdir).with('outgoing')
        expects(:list).with('*.PPR').returns([nil])
      end
      Net::FTP.expects(:new).returns(ftp)
      
      assert_equal [], LightningSource::PurchaseOrderAcknowledgment.fetch(:host => 'localhost', :username => 'root', :password => 'secret')
    end
    
    context "with files on the server" do
      setup do
        ftp = mock 'ftp' do
          expects(:chdir).with('outgoing')
          expects(:list).with('*.PPR').returns(['-rw-r--r--    1 501      482             4 Dec 13 14:42 sample_poa.PPR'])
          expects(:gettextfile)
        end
        Net::FTP.expects(:new).returns(ftp)
      end
      
      should "return all POAs" do
        result = LightningSource::PurchaseOrderAcknowledgment.fetch(:host => 'localhost', :username => 'root', :password => 'secret')
        
        assert_equal 1, result.size
        assert_kind_of LightningSource::PurchaseOrderAcknowledgment, result.first
      end
    end
  end
  
  context "PurchaseOrderAcknowledgment#new" do
    setup do
      file = File.open(File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures/M121314096.PPR'))
      @poa = LightningSource::PurchaseOrderAcknowledgment.new(file)
    end
    
    should "accept the file" do
      assert @poa
    end
    
  end
  
end
