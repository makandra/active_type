# Usecase: Create a STI record, form model decides which type

require 'spec_helper'

ActiveRecord::Migration.class_eval do
  create_table :shapes do |t|
    t.string :type
    t.integer :radius
    t.integer :length
    t.integer :width
  end
end

module ShapeSpec

  class Shape < ActiveType::Record
  end

  class Circle < Shape
    validates :radius, :presence => true
  end

  class Rectangle < Shape
    validates :length, :width, :presence => true
  end

  class ShapeForm < ActiveType::Object
    nests_one :child

    def child_type=(type)
      case type
      when 'circle'
        if child
          self.child = self.child.becomes(Circle)
        else
          self.child = Circle.new
        end
      when 'rectangle'
        if child
          self.child = self.child.becomes(Rectangle)
        else
          self.child = Rectangle.new
        end
      end
    end
  end

end


describe ShapeSpec::ShapeForm do

  let(:form) { ShapeSpec::ShapeForm.new }

  def update(params)
    form.child_type = params[:type]
    form.child_attributes = params.except(:type)
    if form.save
      params['id'] = form.child.id
    end
  end

  it 'can create a circle' do
    params = {
      'type' => 'circle',
      'radius' => '20'
    }.with_indifferent_access

    expect(update(params)).to be_truthy

    expect(ShapeSpec::Circle.all.collect(&:radius)).to eq([20])
    expect(ShapeSpec::Rectangle.count).to eq(0)
  end

  it 'can create a rectangle' do
    params = {
      'type' => 'rectangle',
      'length' => '100',
      'width' => '30'
    }.with_indifferent_access

    expect(update(params)).to be_truthy

    expect(ShapeSpec::Circle.count).to eq(0)
    expect(ShapeSpec::Rectangle.all.collect(&:length)).to eq([100])
    expect(ShapeSpec::Rectangle.all.collect(&:width)).to eq([30])
  end

  it 'can update' do
    params = {
      'type' => 'circle',
      'radius' => '20'
    }.with_indifferent_access
    update(params)

    params['radius'] = '30'
    expect(update(params)).to be_truthy

    expect(ShapeSpec::Circle.all.collect(&:radius)).to eq([30])
  end

  it 'has validations' do
    params = {
      'type' => 'circle'
    }.with_indifferent_access

    expect(update(params)).to be_falsey

    expect(form.child.errors['radius']).to eq(["can't be blank"])
  end

end
