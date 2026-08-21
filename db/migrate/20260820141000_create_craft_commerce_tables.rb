class CreateCraftCommerceTables < ActiveRecord::Migration[8.1]
  def change
    # Add columns to users
    add_column :users, :name, :string, default: ""
    add_column :users, :role, :string, default: "customer", null: false

    # Categories
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end
    add_index :categories, :slug, unique: true

    # Products
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :price, null: false, default: 0
      t.integer :stock_quantity, null: false, default: 0
      t.boolean :is_published, null: false, default: true

      t.timestamps
    end
    add_index :products, :slug, unique: true

    # Product Images
    create_table :product_images do |t|
      t.references :product, null: false, foreign_key: true
      t.string :blob_key
      t.string :filename
      t.integer :display_order, default: 0

      t.timestamps
    end

    # Orders
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.integer :total_amount, null: false, default: 0
      t.string :status, null: false, default: "pending"
      t.string :receipt_blob_key

      t.timestamps
    end
    add_index :orders, :order_number, unique: true

    # Order Items
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :price_at_purchase, null: false
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    # Reviews
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end
    add_index :reviews, [ :user_id, :product_id ]

    # Job Logs
    create_table :job_logs do |t|
      t.string :job_type, null: false
      t.string :status, null: false
      t.text :payload
      t.datetime :finished_at

      t.timestamps
    end
    add_index :job_logs, :job_type
    add_index :job_logs, :status
  end
end
