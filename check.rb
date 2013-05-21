#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'mysql2'
require 'pony'
require "#{File.dirname(__FILE__)}/config"

Pony.options = { 
    :from => $email,
    :via => $mail_transport, 
    :via_options => $mail_options
}
$db = Mysql2::Client.new  :username => $db_user, :database => $db_name
$db.query_options.merge! :cast_booleans => true, :symbolize_keys => true

def process_barcodes
  $db.query('select * from barcodes where is_closed=0').each do |row|
    old_message = get_last_message row[:id]
    new_message = get_new_message row[:barcode]
    if old_message != new_message
      add_log row[:id], new_message
      send_notification  row[:user_id], row[:barcode], new_message
    end
  end
end

def get_last_message(id)
  res = $db.query "select message from logs where barcode_id=#{id} order by id desc limit 1"
  (res.count == 1 && res.first()[:message]) || ""
end

def get_new_message(barcode)
  url = get_url(barcode)
  page = Nokogiri::HTML open url;
  message = page.css('div div')[2].content.strip
end

def get_url(barcode)
  url = 'http://80.91.187.254:8080/servlet/SMCSearch2?lang=en&barcode='
  url+barcode
end

def add_log(barcode_id, message)
  message = $db.escape(message)
  $db.query("insert logs (barcode_id, date,  message) values (#{barcode_id}, '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', '#{message}')")
end

def send_notification user_id, barcode, message
  user_email = $db.query("select email from users where id=#{user_id}").first()[:email]
  subject = "Urkanian Post Pony: %s :  %s" % [barcode, message.truncate(60)]
  body = <<-BODY
    Good day!

    Your parcel with barcode #{barcode.upcase!} was moved on. Now status is:
    #{message}

    Sincerely yours,
    Ukranian Post Pony.
    BODY

  Pony.mail(
    :to => user_email,
    :from => $email,
    :subject => subject,
    :body => body, 
  )
  
  print barcode + " " + user_email + "\n"
end

class String
  def truncate(length = 30, truncate_string = "...")
    text = self.to_s
    if text
      l = length - truncate_string.chars.count
      chars = text.chars
      (chars.count > length ? text[0...l] + truncate_string : text).to_s
    end
  end
end

process_barcodes
