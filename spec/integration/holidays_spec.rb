# Usecase: CRUD a number of records 

require 'spec_helper'

ActiveRecord::Migration.class_eval do
  create_table :holidays do |t|
    t.string :name
    t.date :date
  end
end

module HolidaySpec

  class Holiday < ActiveRecord::Base
    validates :name, :date, :presence => true
  end

  class HolidayForm < ActiveType::Object
    nests_many :holidays, :scope => Holiday, :default => proc { Holiday.all }, :reject_if => :all_blank, :allow_destroy => true
  end

end


describe HolidaySpec::HolidayForm do

  let(:params) do
    {
      '1' => {
        'name' => 'New Year',
        'date' => '2014-01-01',
      },
      '2' => {
        'name' => 'Epiphany',
        'date' => '2014-01-06',
      },
    }
  end

  def update(params)
    form = HolidaySpec::HolidayForm.new(:holidays_attributes => params)
    if form.save
      ids = form.holidays.collect(&:id)
      params.each_with_index do |(key, attributes), index|
        attributes['id'] = ids[index]
      end
      true
    end
  end

  it 'will return holidays including updated ones' do
    HolidaySpec::Holiday.create!(:name => 'New Year', :date => '2014-01-01')
    form = HolidaySpec::HolidayForm.new(:holidays_attributes => params.slice('2'))
    form.holidays.collect(&:name).should == ["New Year", "Epiphany"]
  end

  it 'can create a list of holidays' do
    update(params).should be_true

    holidays = HolidaySpec::Holiday.order(:date)
    holidays.collect(&:name).should == ["New Year", "Epiphany"]
    holidays.collect(&:date).should == [Date.civil(2014, 1, 1), Date.civil(2014, 1, 6)]
  end

  it 'can update holidays' do
    update(params)

    params['1']['name'] += ' 2014'
    params['2']['name'] += ' 2014'
    update(params).should be_true

    holidays = HolidaySpec::Holiday.order(:date)
    holidays.collect(&:name).should == ["New Year 2014", "Epiphany 2014"]
    holidays.collect(&:date).should == [Date.civil(2014, 1, 1), Date.civil(2014, 1, 6)]
  end

  it 'can destroy holidays' do
    update(params)

    params['1']['_destroy'] = '1'
    update(params).should be_true

    holidays = HolidaySpec::Holiday.order(:date)
    holidays.collect(&:name).should == ["Epiphany"]
    holidays.collect(&:date).should == [Date.civil(2014, 1, 6)]
  end

  it 'will not save if some fields are invalid' do
    update(params)

    params['1']['name'] = '-'
    params['1']['_destroy'] = '1'
    params['2']['name'] = ''  # invalid
    update(params).should be_false

    holidays = HolidaySpec::Holiday.order(:date)
    holidays.collect(&:name).should == ["New Year", "Epiphany"]
    holidays.collect(&:date).should == [Date.civil(2014, 1, 1), Date.civil(2014, 1, 6)]
  end


end
