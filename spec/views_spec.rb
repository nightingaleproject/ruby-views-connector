# test for views_ws gem
require_relative '../lib/views/views'

describe Views do

  describe '#validate' do
    context 'provide some valid and error-free data' do
      it 'returns empty array' do
        expect(Views.validate(cause_of_death_line1: 'Heart Attack', cause_of_death_duration1: '1 week')).to be_empty
      end
    end

    context 'provide some data with errors or warnings' do
      it 'returns array with messages' do
        expect(Views.validate(cause_of_death_line1: 'Haert Attack', cause_of_death_duration1: '1 week').size).to eq(1)
      end
    end

    context 'provide full data with no errors or warnings' do
      it 'returns empty array' do
        expect(Views.validate(cause_of_death_line1: 'Heart Attack',
                              cause_of_death_duration1: '1 week',
                              cause_of_death_line2: 'Heart Disease',
                              cause_of_death_duration2: '2 years',
                              cause_of_death_line3: 'Bad Diet',
                              cause_of_death_duration3: '30 years',
                              cause_of_death_line4: 'Fell',
                              cause_of_death_duration4: '32 years',
                              actual_or_presumed_date_of_death: Date.parse('2017-03-02'),
                              date_of_injury: Date.parse('2017-03-01'),
                              time_of_injury: Time.parse('12:30').utc,
                              place_of_injury: 'home',
                              description_of_injury_occurrence: 'fell',
                              transportation_injury_role: 'none',
                              sex: 'M',
                              date_of_birth: Date.parse('1959-03-02'),
                              did_tobacco_use_contribute_to_death: 'N',
                              was_an_autopsy_performed: 'N',
                              were_autopsy_findings_available: 'N',
                              manner_of_death: 'N',
                              injury_at_work: 'N')).to be_empty
      end
    end
  end
end
