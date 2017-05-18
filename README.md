# Views

This is a library for accessing the VIEWS web service.  VIEWS is a validation service provided by the CDC.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'views' :path => 'local path'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install views

## Usage

There is only one function currently available it the library, 'validate'.  It takes all of the fields that can be validated 
as arguments.  All arguments are optional.  The code for using it looks like:

```ruby
    # this block is required even if no configuration is needed, at the moment
    Views.configure do |config|
      #configures to use the Rails logger
      logger = Rails.logger
    end
    @messages = Views.validate(cause_of_death_line1: @death_record&.cause_of_death[0]&.cause, 
                               cause_of_death_duration1: @death_record&.cause_of_death[0]&.interval_to_death,
                               cause_of_death_line2: @death_record&.cause_of_death[1]&.cause, 
                               cause_of_death_duration2: @death_record&.cause_of_death[1]&.interval_to_death,
                               cause_of_death_line3: @death_record&.cause_of_death[2]&.cause, 
                               cause_of_death_duration3: @death_record&.cause_of_death[2]&.interval_to_death,
                               cause_of_death_line4: @death_record&.cause_of_death[3]&.cause, 
                               cause_of_death_duration4: @death_record&.cause_of_death[3]&.interval_to_death,
                               actual_or_presumed_date_of_death: @death_record.actual_or_presumed_date_of_death,
                               date_of_injury: @death_record.date_of_injury,
                               time_of_injury: @death_record.time_of_injury,
                               place_of_injury: @death_record.place_of_injury, 
                               description_of_injury_occurrence: @death_record.description_of_injury_occurrence,
                               transportation_injury_role: @death_record.transportation_injury_role,
                               sex: @death_record.sex,
                               date_of_birth: @death_record.date_of_birth,
                               did_tobacco_use_contribute_to_death: @death_record.did_tobacco_use_contribute_to_death,
                               was_an_autopsy_performed: @death_record.was_an_autopsy_performed,
                               were_autopsy_findings_available: @death_record.were_autopsy_findings_available,
                               manner_of_death: @death_record.manner_of_death,
                               injury_at_work: @death_record.injury_at_work)
```


