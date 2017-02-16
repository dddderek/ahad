# require 'rails_helper' # works, but takes forever to load rails
require 'spec_helper'
require_relative '../../app/helpers/properties_helper'

RSpec.describe "PropertiesHelper", :type => :helper do

  include PropertiesHelper # not needed when requiring rails_helper
  
  describe "#normalize_address" do

    it "uppercases" do
      expect(normalize_address("259 Acacia St"))
        .to eq("259 ACACIA ST")
    end

    it "removes leading whitespace" do
      expect(normalize_address("  259 ACACIA ST"))
        .to eq("259 ACACIA ST")
    end

    it "removes trailing whitespace" do
      expect(normalize_address("259 ACACIA ST  \t  "))
        .to eq("259 ACACIA ST")
    end

    it "turns 2 or more whitespace chars in between " +
       "words into a single space" do
      expect(normalize_address("259  ACACIA   \t ST"))
        .to eq("259 ACACIA ST")
    end

    it "turns tabs into spaces" do
      expect(normalize_address("259\tACACIA ST"))
        .to eq("259 ACACIA ST")
      expect(normalize_address("\t259\tACACIA\t\tST\t"))
        .to eq("259 ACACIA ST")
    end

    it "treats tabs adjacent to spaces as spaces" do
      expect(normalize_address("259 \tACACIA\t ST\t"))
        .to eq("259 ACACIA ST")
    end

    expected_values = {
      '259 ACACIA ST.': '259 ACACIA ST', 
      '259 ACACIA STREET': '259 ACACIA ST',
      '1437 ALPHA AVE.': '1437 ALPHA AVE', 
      '1437 ALPHA AVENUE': '1437 ALPHA AVE',
      '3544 CANON BLVD.': '3544 CANON BLVD', 
      '3544 CANON BOULEVARD': '3544 CANON BLVD',
      '3705 ALZADA RD.': '3705 ALZADA RD',
      '3705 ALZADA ROAD': '3705 ALZADA RD',
      '2115 ALTA PASA DR.': '2115 ALTA PASA DR', 
      '2115 ALTA PASA DRIVE': '2115 ALTA PASA DR',
      '607 BARRY PL.': '607 BARRY PL', 
      '607 BARRY PLACE': '607 BARRY PL',
      '3260 ALEGRE LN.': '3260 ALEGRE LN', 
      '3260 ALEGRE LANE': '3260 ALEGRE LN',
      '1314 SUNNY OAKS CIR.': '1314 SUNNY OAKS CIR', 
      '1314 SUNNY OAKS CIRCLE': '1314 SUNNY OAKS CIR',
      '1277 AVOCADO TER.': '1277 AVOCADO TER', 
      '1277 AVOCADO TERRACE': '1277 AVOCADO TER',
      '2756 BULA CT.': '2756 BULA CT', 
      '2756 BULA COURT': '2756 BULA CT',
      '3430 CHANEY TR.': '3430 CHANEY TR', 
      '3430 CHANEY TRAIL': '3430 CHANEY TR',
      '1080 BEVERLY WY.': '1080 BEVERLY WAY', 
      '1080 BEVERLY WY': '1080 BEVERLY WAY',
      
      '1367 NORTH ALTADENA DR': '1367 N ALTADENA DR', 
      '92 EAST HARRIET ST': '92 E HARRIET ST', 
      '419 WEST PALM ST': '419 W PALM ST',
      '111 SOUTH FICTITIOUS LN': '111 S FICTITIOUS LN',

      '1000 E MOUNT CURVE AVE': '1000 E MT CURVE AVE', 
      '1099 MOUNT LOWE DR': '1099 MT LOWE DR' # no comma
    }
    
    expected_values.each do |val, expected| 
      it "returns #{expected} when input is #{val}" do 
        expect(normalize_address(val.to_s)).to eq(expected)
      end
    end  

    it "passes a wacky contrived whitespace test of a mix of the above" do
      expect(normalize_address("  \t259 EAST \tAcaCia   st.   \t  "))
        .to eq("259 E ACACIA ST")
    end

  end # #normalize_address
    
end
