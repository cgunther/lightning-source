require 'helper'
require 'net/ftp'
require 'tempfile'

class TestPurchaseOrderAcknowledgment < Test::Unit::TestCase
  
  context "PurchaseOrderAcknowledgment.fetch" do
    
    should "return empty array if no POA's exist" do
      ftp = mock 'ftp' do
        expects(:chdir).with('outgoing')
        expects(:list).with('*.PPR').returns([nil])
        expects(:close)
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
          expects(:close)
        end
        Net::FTP.expects(:new).returns(ftp)
        Tempfile.expects(:new).returns(File.open(File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures/M121314096.PPR')))
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
    
    should "set the client_identification" do
      assert_equal 'OFFBKS', @poa.client_identification
    end
    
    should "set the batch_id" do
      assert_equal 157, @poa.batch_id
    end
    
    should "set the batch_date" do
      assert_equal Date.parse('2010-12-13'), @poa.batch_date
    end
    
    should "set the batch_time" do
      assert_equal '14:09:27', @poa.batch_time
    end
    
    context "orders" do
      setup { @order = @poa.orders.first}
      
      should "set the orders" do
        assert_equal 1, @poa.orders.size
      end

      should "set the client_order_number" do
        assert_equal '954', @order.client_order_number
      end

      should "set the client_order_date" do
        assert_equal Date.parse('2010-12-13'), @order.client_order_date
      end

      should "not set any errors" do
        assert_nil @order.errors
      end
      
      context "items" do
        setup { @item = @order.items.first }
        
        should "set the order's items" do
          assert_equal 1, @poa.orders.first.items.size
        end

        should "set the line_item_number" do
          assert_equal 947, @item.line_item_number
        end

        should "set the title_id" do
          assert_equal '0982771614', @item.title_id
        end

        should "set the order_quantity" do
          assert_equal 1, @item.order_quantity
        end

        should "set the title_id_13" do
          assert_equal '9780982771617', @item.title_id_13
        end
        
        should "set the status_code" do
          assert_equal 'AR', @item.status_code
        end
        
        should "set the ship_quantity" do
          assert_equal 1, @item.ship_quantity
        end
        
        should "not set an error" do
          assert_nil @item.error
        end
      end
    end
  end
  
end
