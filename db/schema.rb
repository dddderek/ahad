# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  create_table "TESTnotesource", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid"
    t.text    "nscleaned", limit: 65535
    t.text    "nsraw",     limit: 65535
  end

  create_table "additionalarchitect", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",               null: false
    t.string  "name",     limit: 128, null: false
    t.string  "year",     limit: 32
    t.string  "yearflag", limit: 1
    t.index ["propid"], name: "propid", using: :btree
    t.index ["yearflag"], name: "yearflag", using: :btree
  end

  create_table "additionalbuilder", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",               null: false
    t.string  "name",     limit: 128, null: false
    t.string  "year",     limit: 32
    t.string  "yearflag", limit: 1
    t.index ["propid"], name: "propid", using: :btree
    t.index ["yearflag"], name: "yearflag", using: :btree
  end

  create_table "ahdesignationvalue", primary_key: "value", id: :string, limit: 128, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["value"], name: "value", unique: true, using: :btree
  end

  create_table "alteration", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",                  null: false
    t.integer "cost"
    t.string  "description", limit: 128
    t.string  "year",        limit: 32
    t.string  "yearflag",    limit: 1
    t.index ["propid"], name: "propid", using: :btree
    t.index ["yearflag"], name: "yearflag", using: :btree
  end

  create_table "apn", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",            null: false
    t.string  "parcel", limit: 16, null: false
    t.index ["propid"], name: "propid", using: :btree
  end

  create_table "buildingpermit", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",              null: false
    t.string  "permit",   limit: 32, null: false
    t.string  "year",     limit: 32
    t.string  "yearflag", limit: 1
    t.index ["propid"], name: "propid", using: :btree
    t.index ["yearflag"], name: "yearflag", using: :btree
  end

  create_table "chrscode", primary_key: "code", id: :string, limit: 6, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["code"], name: "code", unique: true, using: :btree
  end

  create_table "formeraddress", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",               null: false
    t.string  "address1", limit: 128, null: false
    t.string  "address2", limit: 128, null: false
    t.string  "years",    limit: 64
    t.string  "yearflag", limit: 1
    t.index ["propid"], name: "propid", using: :btree
  end

  create_table "otherowner", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",               null: false
    t.string  "name",     limit: 128, null: false
    t.string  "years",    limit: 32
    t.string  "yearflag", limit: 1
    t.index ["propid"], name: "propid", using: :btree
    t.index ["yearflag"], name: "yearflag", using: :btree
  end

  create_table "photo", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",                  null: false
    t.string  "filename",    limit: 64,  null: false
    t.string  "description", limit: 128
    t.index ["filename"], name: "filename", unique: true, using: :btree
    t.index ["propid"], name: "propid", using: :btree
  end

  create_table "photos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",                 null: false
    t.string  "filename",    limit: 45
    t.string  "description"
    t.index ["propid"], name: "propid_index", using: :btree
  end

  create_table "property", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "streetnumberbegin",       limit: 16
    t.string "streetnumberend",         limit: 16
    t.string "streetname",              limit: 64
    t.string "streetdirection",         limit: 1
    t.string "addressnote",             limit: 128
    t.string "address1",                limit: 128
    t.string "address2",                limit: 128
    t.string "ahdesignation",           limit: 128
    t.string "architect",               limit: 128
    t.string "architectconfirmed",      limit: 1
    t.string "builder",                 limit: 128
    t.string "builderconfirmed",        limit: 1
    t.string "chrs",                    limit: 32
    t.string "currentlotsize",          limit: 64
    t.string "historicname",            limit: 128
    t.string "legaldescription",        limit: 64
    t.string "movedontoproperty",       limit: 1
    t.string "originalcost",            limit: 32
    t.string "originallotsize",         limit: 64
    t.string "originalowner",           limit: 64
    t.string "originalownerspouse",     limit: 64
    t.string "originalowneroccupation", limit: 64
    t.string "placeofbusiness",         limit: 64
    t.string "quadrant",                limit: 32
    t.string "stories",                 limit: 32
    t.string "style",                   limit: 32
    t.string "type",                    limit: 32
    t.string "yearbuilt",               limit: 32
    t.string "yearbuiltflag",           limit: 1
    t.string "yearbuiltassessor",       limit: 32
    t.string "yearbuiltassessorflag",   limit: 1
    t.string "yearbuiltother",          limit: 32
    t.string "yearbuiltotherflag",      limit: 1
    t.string "orig_note_shpo_sources",  limit: 10000
    t.string "notes_shpo_and_sources",  limit: 10000
    t.index ["architectconfirmed"], name: "architectconfirmed", using: :btree
    t.index ["builderconfirmed"], name: "builderconfirmed", using: :btree
    t.index ["movedontoproperty"], name: "movedontoproperty", using: :btree
    t.index ["quadrant"], name: "quadrant", using: :btree
    t.index ["streetdirection"], name: "streetdirection", using: :btree
    t.index ["style"], name: "style", using: :btree
    t.index ["type"], name: "type", using: :btree
    t.index ["yearbuiltassessorflag"], name: "yearbuiltassessorflag", using: :btree
    t.index ["yearbuiltflag"], name: "yearbuiltflag", using: :btree
  end

  create_table "quadrantvalue", primary_key: "value", id: :string, limit: 32, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["value"], name: "value", unique: true, using: :btree
  end

  create_table "scandoc", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "propid",                  null: false
    t.string  "filename",    limit: 64,  null: false
    t.string  "description", limit: 128
    t.index ["filename"], name: "filename", unique: true, using: :btree
    t.index ["propid"], name: "propid", using: :btree
  end

  create_table "streetdirectionvalue", primary_key: "value", id: :string, limit: 1, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["value"], name: "value", unique: true, using: :btree
  end

  create_table "stylevalue", primary_key: "value", id: :string, limit: 32, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["value"], name: "value", unique: true, using: :btree
  end

  create_table "typevalue", primary_key: "value", id: :string, limit: 32, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["value"], name: "value", unique: true, using: :btree
  end

  create_table "yearflag", primary_key: "flag", id: :string, limit: 1, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "description", limit: 32
    t.index ["flag"], name: "flag", unique: true, using: :btree
  end

  create_table "yesnoflag", primary_key: "flag", id: :string, limit: 1, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.index ["flag"], name: "flag", unique: true, using: :btree
  end

  add_foreign_key "additionalarchitect", "property", column: "propid", name: "additionalarchitect_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "additionalarchitect", "yearflag", column: "yearflag", primary_key: "flag", name: "additionalarchitect_ibfk_1"
  add_foreign_key "additionalbuilder", "property", column: "propid", name: "additionalbuilder_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "additionalbuilder", "yearflag", column: "yearflag", primary_key: "flag", name: "additionalbuilder_ibfk_1"
  add_foreign_key "alteration", "property", column: "propid", name: "alteration_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "alteration", "yearflag", column: "yearflag", primary_key: "flag", name: "alteration_ibfk_1"
  add_foreign_key "apn", "property", column: "propid", name: "apn_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "buildingpermit", "property", column: "propid", name: "buildingpermit_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "buildingpermit", "yearflag", column: "yearflag", primary_key: "flag", name: "buildingpermit_ibfk_1"
  add_foreign_key "formeraddress", "property", column: "propid", name: "formeraddress_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "otherowner", "property", column: "propid", name: "otherowner_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "otherowner", "yearflag", column: "yearflag", primary_key: "flag", name: "otherowner_ibfk_1"
  add_foreign_key "photo", "property", column: "propid", name: "photo_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "property", "quadrantvalue", column: "quadrant", primary_key: "value", name: "property_ibfk_3"
  add_foreign_key "property", "streetdirectionvalue", column: "streetdirection", primary_key: "value", name: "property_ibfk_4"
  add_foreign_key "property", "stylevalue", column: "style", primary_key: "value", name: "property_ibfk_5"
  add_foreign_key "property", "typevalue", column: "type", primary_key: "value", name: "property_ibfk_6"
  add_foreign_key "property", "yearflag", column: "yearbuiltassessorflag", primary_key: "flag", name: "property_ibfk_8"
  add_foreign_key "property", "yearflag", column: "yearbuiltflag", primary_key: "flag", name: "property_ibfk_7"
  add_foreign_key "property", "yesnoflag", column: "architectconfirmed", primary_key: "flag", name: "property_ibfk_1"
  add_foreign_key "property", "yesnoflag", column: "builderconfirmed", primary_key: "flag", name: "property_ibfk_2"
  add_foreign_key "property", "yesnoflag", column: "movedontoproperty", primary_key: "flag", name: "property_ibfk_9"
  add_foreign_key "scandoc", "property", column: "propid", name: "scandoc_ibfk_1", on_update: :cascade, on_delete: :cascade
end
