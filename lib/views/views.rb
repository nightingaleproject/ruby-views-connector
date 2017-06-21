# VIEWS WS gem
require 'views/version'
require 'nokogiri'
require 'savon'

# the Views module
module Views

  WSDL = 'https://wwwn.cdc.gov/view2_admin/VIEWS/ValidationService.svc?wsdl'
  SSL_VERIFY_MODE = :none
  SOAP_VERSION = 2

  def self.validate(cause_of_death_line1: '',
                    cause_of_death_duration1: '',
                    cause_of_death_line2: '',
                    cause_of_death_duration2: '',
                    cause_of_death_line3: '',
                    cause_of_death_duration3: '',
                    cause_of_death_line4: '',
                    cause_of_death_duration4: '',
                    actual_or_presumed_date_of_death: nil,
                    date_of_injury: nil,
                    time_of_injury: nil,
                    place_of_injury: '',
                    description_of_injury_occurrence: '',
                    transportation_injury_role: '',
                    sex: '',
                    date_of_birth: nil,
                    did_tobacco_use_contribute_to_death: nil,
                    was_an_autopsy_performed: nil,
                    were_autopsy_findings_available: nil,
                    manner_of_death: '',
                    injury_at_work: '')

    # initialize Savon (SOAP WS) client
    client = Savon.client(wsdl: Views::WSDL,
                          ssl_verify_mode: Views::SSL_VERIFY_MODE,
                          soap_version: Views::SOAP_VERSION,
                          headers: { 'wsa:To' => 'https://wwwn.cdc.gov/view2_admin/VIEWS/ValidationService.svc' },
                          use_wsa_headers: true,
                          pretty_print_xml: true,
                          log: false)

    # create array of values to create

    # build the xml message
    # TODO: this should be done by the Savon client, had issues getting it working, fix
    message = "<input>
&lt;Certificate Year='2000' State='NC' ID='012345' xmlns='WebMMDS'
ValidateAbbreviations=\"Y\" ABBRStrict=\"1\"
ValidateMedicalEdits=\"Y\" MEDEDITStrict=\"1\"
ValidateRareCauses=\"Y\" RARECAUSEStrict=\"1\"
ValidateIllTrivial=\"Y\" ValidateSpelling=\"Y\"
ValidateSurveillance=\"Y\" ValidateMannerOfDeath=\"Y\"
TermCasing=\"UPPER\"&gt;\n"

    add(message, 'Line1a', cause_of_death_line1)
    add(message, 'Line1b', cause_of_death_line2)
    add(message, 'Line1c', cause_of_death_line3)
    add(message, 'Line1d', cause_of_death_line4)
    # TODO:  Add other significant conditions - not present in model
    add(message, 'Duration1a', cause_of_death_duration1)
    add(message, 'Duration1b', cause_of_death_duration2)
    add(message, 'Duration1c', cause_of_death_duration3)
    add(message, 'Duration1d', cause_of_death_duration4)
    add(message, 'YearOfDeath', parse_date(actual_or_presumed_date_of_death, :year))
    add(message, 'MonthOfDeath', parse_date(actual_or_presumed_date_of_death, :month))
    add(message, 'DayOfDeath', parse_date(actual_or_presumed_date_of_death, :day))
    # TODO: Month, Day, Year of Surgery can be added here
    add(message, 'YearOfInjury', parse_date(date_of_injury, :year))
    add(message, 'MonthOfInjury', parse_date(date_of_injury, :month))
    add(message, 'DayOfInjury', parse_date(date_of_injury, :day))
    add(message, 'HourOfInjury', parse_hour(time_of_injury))
    # InjuryTimeCode indicates the format for the HourOfInjury 'M' = military time
    add(message, 'InjuryTimeCode', 'M') if time_of_injury
    add(message, 'PlaceOfInjury', place_of_injury)
    add(message, 'InjuryDescription', description_of_injury_occurrence)
    add(message, 'Transport', transportation_injury_role)
    add(message, 'Sex', sex)
    add(message, 'AgeUnits', '1') # ?? totally unclear what the allowed values mean here, guessing 1 is 'years'
    add(message, 'Age', calculate_age(date_of_birth))
    add(message, 'TobaccoUse', translate_tobacco(did_tobacco_use_contribute_to_death))
    add(message, 'Autopsy', translate_yes_no_unknown(was_an_autopsy_performed))
    add(message, 'AutopsyFindings', translate_yes_no_unknown(were_autopsy_findings_available))
    # pregnancy is coded using numbers, with no idea what they mean, skipping for now
    # TODO:  figure this out and add
    # add('Pregnancy', translatePregnancyStatus(pregnancy_status)
    add(message, 'MannerOfDeath', translate_manner_of_death(manner_of_death))
    add(message, 'WorkInjury', translate_yes_no_unknown(injury_at_work))
    # activity code is also some kind of number without documentation
    # TODO:  Add if needed

    message << '&lt;/Certificate&gt;
</input>'

    # NOTE:  The 'attributes' bit below is required to get this to work properly.
    # otherwise the 'Validate' tag isn't correctly created in the SOAP body
    response = client.call(:validate, message: message,
                                      attributes: { 'xmlns:ns2' => 'http://schemas.microsoft.com/2003/10/Serialization/',
                                                    'xmlns' => 'http://tempuri.org/' })

    parse_response(response.body[:validate_response][:validate_result].to_s)
  end
end

private

def add(message, tag, value)
  if value
    message << '&lt;' << tag << '&gt;' << value << '&lt;/' << tag << "&gt;\n" if value && value != ''
  end
end

def parse_date(d, type)
  if d
    case type
    when :year
      response = d&.year.to_s
    when :month
      response = d&.month.to_s
      response = response.rjust(2, '0') if response
    when :day
      response = d&.day.to_s
      response = response.rjust(2, '0') if response
    end
    response
  end
end

def parse_hour(time)
  response = time&.hour.to_s if time
  response = response.ljust(4, '0') if response
  response
end

def calculate_age(dob)
  if dob
    now = Time.now.utc.to_date
    response = now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
    # age must be no more than 130
    response = 130 if response > 130
    response.to_s.rjust(3, '0')
  end
end

def translate_tobacco(tobacco_use)
  case tobacco_use
  when 'Yes'
    'Y'
  when 'No'
    'N'
  when 'Probably'
    'P'
  when 'Unknown'
    'U'
  end
end

def translate_yes_no_unknown(val)
  case val
  when 'Yes'
    'Y'
  when 'No'
    'N'
  when 'Unknown'
    'U'
  end
end

def translate_manner_of_death(val)
  case val
  when 'Natural'
    'N'
  when 'Accident'
    'A'
  when 'Suicide'
    'S'
  when 'Homicide'
    'H'
  when 'Pending Investigation'
    'P'
  when 'Could not be determined'
    'C'
  end
end

def parse_response(response)
  return '' unless response
  doc = Nokogiri::XML(response)
  messages = []
  begin
    list = doc.xpath('//WebMMDS:ValidationData', WebMMDS: 'WebMMDS')
    list&.each do |message|
      type = message.at_xpath('@type')&.text
      field = message.at_xpath('@field')&.text
      term = message.at_xpath('./WebMMDS:Term', WebMMDS: 'WebMMDS')&.text
      case type
      when 'Information'
        if msg = message.at_xpath('./WebMMDS:Message[@level=3]', WebMMDS: 'WebMMDS')
          messages << { type: type, message: 'Error occured running VIEWS validation: ' + msg.text.to_s }
        end
      when 'Spelling'
        if suggestions = message.xpath('./WebMMDS:Suggestion', WebMMDS: 'WebMMDS')
          messages << { type: type, field: field, term: term, message: "VIEWS detected an issue with the spelling of '#{term}'", suggestions: suggestions.map(&:text) }
        end
      when 'RareWord'
        suggestions = message.xpath('./WebMMDS:Suggestion', WebMMDS: 'WebMMDS')
        msg = message.at_xpath('./WebMMDS:Message[@level=3]', WebMMDS: 'WebMMDS')
        if suggestions && msg
          messages << { type: type, field: field, term: term, message: msg.text, suggestions: suggestions.map(&:text) }
        end
      when 'Surveillance'
        if msg = message.at_xpath('./WebMMDS:Message[@level=3]', WebMMDS: 'WebMMDS')
          messages << { type: type, field: field, term: term, message: msg.text }
        end
      end
    end
  rescue StandardError => err
    messages << { message: 'Unable to run VIEWS validation, error occured.  Contact System Administrator.' }
    raise
  end

  # handle error case
  # TODO:  Implement

  messages
end
