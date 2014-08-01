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
    attribute :child, :accepts_nested_attributes => true

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

    update(params).should be_true

    ShapeSpec::Circle.all.collect(&:radius).should == [20]
    ShapeSpec::Rectangle.count.should == 0
  end

  it 'can create a rectangle' do
    params = {
      'type' => 'rectangle',
      'length' => '100',
      'width' => '30'
    }.with_indifferent_access

    update(params).should be_true

    ShapeSpec::Circle.count.should == 0
    ShapeSpec::Rectangle.all.collect(&:length).should == [100]
    ShapeSpec::Rectangle.all.collect(&:width).should == [30]
  end

  it 'can update' do
    params = {
      'type' => 'circle',
      'radius' => '20'
    }.with_indifferent_access
    update(params)

    params['radius'] = '30'
    update(params).should be_true

    ShapeSpec::Circle.all.collect(&:radius).should == [30]
  end

  it 'has validations' do
    params = {
      'type' => 'circle'
    }.with_indifferent_access

    update(params).should be_false

    form.child.errors['radius'].should == ["can't be blank"]
  end

end
