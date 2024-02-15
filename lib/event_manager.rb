require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'



def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
      ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def phone_numbers(phone_number)
  number = phone_number.gsub(/\D/, '')
  if number.length != 10
    return (number.length == 11) && (number[0] == "1") ? number[1..10] : "bad number"
  end
  number
end

def take_hour(dates)
  DateTime.strptime(dates, '%m/%d/%Y %H:%M').hour
end

def most_hour(values)
  max = values.tally.values.max
  values.tally.select { |key, value| value == max }.keys
end
puts 'Event manager Initialized!'
puts ""

def contents 
  CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def write_letter
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id,form_letter)
  end
end

def get_phone_number
  contents.each do |row|
    phone = phone_numbers(row[:homephone])
    puts phone
  end
end

get_phone_number

def get_most_visited_hour
  hours = []
  contents.each do |row|
    hours.push(take_hour(row[:regdate]))
    # p hours
  end
  # hours.tally
  most_hour(hours).each { |item| puts "The most visited hour is #{item}:00" }
end

get_most_visited_hour