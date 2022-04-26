require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

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
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..10]
  else
    'Wrong number!'
  end
end

def most_common_reg_hour
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  reg_day_hour_arr = []
  contents.each do |row|
    date_time = row[:regdate]
    reg_hour = Time.strptime(date_time, "%m/%d/%Y %k:%M").hour
    reg_day_hour_arr.push(reg_hour)
  end
  most_common_hour = reg_day_hour_arr.reduce(Hash.new(0)) do |hash, hour|
    hash[hour] += 1
    hash
  end
  most_common_hour.max_by { |_k, v| v }[0]
end

def most_common_reg_day
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  reg_day_day_arr = []
  contents.each do |row|
    date_time = row[:regdate]
    reg_day = Date.strptime(date_time, "%m/%d/%Y %k:%M").strftime('%A')
    reg_day_day_arr.push(reg_day)
  end
  most_common_day = reg_day_day_arr.reduce(Hash.new(0)) do |hash, day|
    hash[day] += 1
    hash
  end
  most_common_day.max_by { |_k, v| v }[0]
end

puts 'EventManager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])

  date_time = row[:regdate]

  day = Date.strptime(date_time, "%m/%d/%Y %k:%M").strftime('%A')

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  puts "#{day} #{name} #{phone_number}"
end

puts "This is the most common hour of registration: #{most_common_reg_hour}:00."
puts "This is the most common day of registration: #{most_common_reg_day}."
# Everything bellow this line is building a CSV parser from scratch just to understand how it's done.

# contents = File.read('event_attendees.csv')
# puts contents

# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line,index|
#     next if index == 0
#     columns = line.split(",")
#     name = columns[2]
#     puts name
# end
