class CreateDistributionLists < ActiveRecord::Migration
  def self.up
    create_table :distribution_lists do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :distribution_lists
  end
end
