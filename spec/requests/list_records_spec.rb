require 'spec_helper'

describe 'OIA-PMH ListRecords Request' do
  let(:xml) { Nokogiri::XML(response.body) }
  let(:namespaces) do
    {
      dc: 'http://purl.org/dc/elements/1.1/',
      xmlns: 'http://www.openarchives.org/OAI/2.0/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    }
  end

  context 'for all documents' do
    before :example do
      get '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc'
    end

    it 'returns 25 records' do
      expect(xml.xpath('//xmlns:ListRecords/xmlns:record/xmlns:header').count).to eql 25
    end

    it 'first record has oai_dc metadata element' do
      expect(xml.at_xpath('//xmlns:ListRecords/xmlns:record/xmlns:metadata/oai_dc:dc', namespaces)).not_to be_nil
    end

    it 'contains resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken').text).to eql 'oai_dc.f(2014-02-03T18:42:53Z).u(2014-03-03T18:42:53Z).t(30):25'
    end

    context 'metadata element' do
      let(:metadata_node) {
        xml.xpath(
          '//xmlns:ListRecords/xmlns:record/xmlns:header/xmlns:identifier[text()="test/2007020969"]/parent::*/parent::*/xmlns:metadata/oai_dc:dc',
          namespaces
        )
      }

      it 'contains title' do
        expect(metadata_node.at_xpath('dc:title', namespaces).text).to eql '"Strong Medicine speaks"'
      end

      it 'contains creator' do
        expect(metadata_node.at_xpath('dc:creator', namespaces).text).to eql 'Hearth, Amy Hill, 1958-'
      end

      it 'contains type' do
        expect(metadata_node.at_xpath('dc:date', namespaces).text).to eql '2008'
      end

      it 'contains language' do
        expect(metadata_node.at_xpath('dc:language', namespaces).text).to eql 'English'
      end

      it 'contains identifier' do
        expect(metadata_node.at_xpath('dc:format', namespaces).text).to eql 'Book'
      end
    end
  end

  context 'with resumption_token' do
    before :example do
      get '/catalog/oai?verb=ListRecords&resumptionToken=oai_dc.f(2014-02-03T18:42:53Z).u(2014-02-03T18:42:53Z).t(30):25'
    end

    it 'returns 5 records' do
      expect(xml.xpath('//xmlns:ListRecords/xmlns:record/xmlns:header').count).to eql 5
    end

    it 'first record has oai_dc metadata element' do
      expect(xml.at_xpath('//xmlns:ListRecords/xmlns:record/xmlns:metadata/oai_dc:dc', namespaces)).not_to be_nil
    end

    it 'does not contain a resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken').text).to eql ''
    end
  end

  context 'for all documents within a time range' do
    before :example do
      get '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc&from=2014-03-03&until=2014-04-03'
    end

    it 'returns 1 record' do
      expect(xml.xpath('//xmlns:ListRecords/xmlns:record/xmlns:header').count).to eql 1
    end

    it 'does not contain a resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken')).to be_nil
    end
  end

  context 'throws noRecordsMatch error' do
    before :example do
      get '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc&from=2015-01-01'
    end

    it 'returns no records error' do
      expect(xml.at_xpath('//xmlns:error').attribute('code').text).to eql 'noRecordsMatch'
    end
  end

  context 'throws badArgument error' do
    it 'when metadataPrefix argument missing' do
      get '/catalog/oai?verb=ListRecords'
      expect(xml.at_xpath('//xmlns:error[@code]').attribute('code').text).to eql 'badArgument'
    end

    it "when date is invalid" do
      get '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc&from=2012-01-f01'
      expect(xml.at_xpath('//xmlns:error[@code]').attribute('code').text).to eql 'badArgument'
    end
  end

  context 'throws badResumptionToken error' do
    it 'when resumptionToken is invalid' do
      get '/catalog/oai?verb=ListRecords&resumptionToken=blahblahblah'
      expect(xml.at_xpath('//xmlns:error').attribute('code').text).to eql 'badResumptionToken'
    end
  end
end