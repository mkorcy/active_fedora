require 'spec_helper'

describe ActiveFedora::ChangeSet do
  let(:change_set) { described_class.new(base, base.resource, base.changed_attributes.keys) }
  subject { change_set }

  context "with an unchanged object" do
    let(:base) { ActiveFedora::Base.new }

    it { is_expected.to be_empty }
  end

  context "with a changed object" do
    before do
      class Library < ActiveFedora::Base
      end

      class Book < ActiveFedora::Base
        belongs_to :library, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasConstituent
        property :title, predicate: ::RDF::DC.title
        property :alt_id, predicate: ::RDF::DC.identifier
      end

      base.library_id = 'foo'
      base.title = ['bar']
      base.alt_id = ['12345']
    end
    after do
      Object.send(:remove_const, :Library)
      Object.send(:remove_const, :Book)
    end

    let(:base) { Book.create }


    describe "#changes" do
      subject { change_set.changes }

      it { is_expected.to be_kind_of Hash }

      it "should have three elements" do
        expect(subject.size).to eq 3
      end
      it "should not include URIs from other objects" do
        base.resource << RDF::Statement.new(RDF::URI("http://wrong.com"), RDF::DC.title, "bad")
        base.title = nil
        expect(subject[RDF::DC.title].to_a).to eq []
      end
      it "should include hash URIs" do
        # This is useful as an alternative to blank nodes.
        hash_uri = RDF::URI(base.uri.to_s + "#test")
        base.resource << RDF::Statement.new(hash_uri, RDF::DC.title, "good")
        base.title = [RDF::URI(hash_uri)]
        expect(subject[RDF::DC.title].to_a).not_to eq []
        # Include the title reference and the title for the hash URI
        expect(subject[RDF::DC.title].to_a.length).to eq 2
      end
    end

    it { is_expected.to_not be_empty }
  end
end
