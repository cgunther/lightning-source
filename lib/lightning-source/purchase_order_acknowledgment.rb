module LightningSource
  class PurchaseOrderAcknowledgment < Base
    
    attr_accessor :client_identification, :batch_id, :batch_date, :batch_time
    
    Order = Struct.new(:client_order_number, :client_order_date, :errors) do
      def items
        @items ||= []
      end
    end
    
    # TODO: Add helper methods like #accepted?, #cancelled?, etc.
    Item = Struct.new(:line_item_number, :title_id, :order_quantity, :title_id_13, :status_code, :ship_quantity, :error)
    
    def self.fetch(opts)
      require 'net/ftp'
      require 'tempfile'
      
      ftp = Net::FTP.new(opts[:host], opts[:username], opts[:password])
      ftp.chdir('outgoing')
      result = ftp.list('*.PPR').compact.map do |file|
        filename = file.split[-1]
        tempfile = Tempfile.new(filename)
        ftp.gettextfile(filename, tempfile.path)
        PurchaseOrderAcknowledgment.new(tempfile)
      end
      ftp.close
      result
    end
    
    def initialize(raw_data)
      @raw_data = raw_data.read
      
      expected_data_record_count = parse_numeric(@raw_data.lines.to_a[-1][35..41])
      actual_data_record_count = @raw_data.lines.to_a.size - 2
      
      if @raw_data.lines.to_a[0] !~ /^\$\$HDR/ || @raw_data.lines.to_a[-1] !~ /^\S\SEOF/ ||
        expected_data_record_count != actual_data_record_count
        raise 'malformed file'
      end
      
      @raw_data.each_line do |line|
        if line[0..4] == '$$HDR'
          parse_batch_header line
        elsif line[0..1] == 'H1'
          # TODO: Test multiple orders in a single POA
          parse_header line
        elsif line[0..1] == 'H2'
          # TODO: Handle POA Header Error Message
        elsif line[0..1] == 'D1'
          parse_line_item line
        elsif line[0..1] == 'D2'
          parse_line_item_error_message line
        end
      end
    end
    
    def orders
      @orders ||= []
    end
    
  private
  
    def parse_batch_header(raw_data)
      self.client_identification = raw_data[5..10]
      self.batch_id = parse_numeric(raw_data[11..20])
      self.batch_date = parse_date(raw_data[21..28])
      self.batch_time = parse_time(raw_data[29..34])
    end
    
    def parse_header(raw_data)
      order = Order.new
      order.client_order_number = parse_string(raw_data[12..26])
      order.client_order_date = parse_date(raw_data[27..34])
      orders << order
    end
    
    def parse_line_item(raw_data)
      client_order_number = parse_string(raw_data[12..26])
      item = Item.new
      item.line_item_number = parse_numeric(raw_data[27..31])
      item.title_id = raw_data[32..41]
      item.order_quantity = parse_numeric(raw_data[42..50])
      item.title_id_13 = parse_string(raw_data[51..70])
      orders.find { |o| o.client_order_number == client_order_number }.items << item
    end
    
    def parse_line_item_error_message(raw_data)
      client_order_number = parse_string(raw_data[12..26])
      line_item_number = parse_numeric(raw_data[27..31])
      order = orders.find { |o| o.client_order_number == client_order_number }
      item = order.items.find { |i| i.line_item_number == line_item_number }
      
      item.status_code = raw_data[42..43]
      item.ship_quantity = parse_numeric(raw_data[44..52])
    end
    
  end
end
