# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require 'avro'
require 'logstash/codecs/confluent'
require 'logstash/event'

describe LogStash::Codecs::Confluent do

  let (:confluent_config) {
    { 'schema_registry_url' => nil, 'incl_schema_metadata' => false}
  }

  let (:test_schema) {
    '{"type": "record", "name": "Test", "fields": [{"name": "foo", "type": ["null", "string"]}, {"name": "bar", "type": "int"}]}'
  }

  let (:test_schema_id) { 123 }

  let (:test_event) { LogStash::Event.new({"foo" => "hello", "bar" => 10}) }
  let (:test_event_with_schema) { LogStash::Event.new({"foo" => "hello", "bar" => 10, "@metadata" => {"@schema" => test_schema}}) }

  subject do
    allow_any_instance_of(LogStash::Codecs::Confluent).to receive(:read_schema).with(test_schema_id).and_return(test_schema)
    allow_any_instance_of(LogStash::Codecs::Confluent).to receive(:register_schema).with(test_schema).and_return(test_schema_id)
    next LogStash::Codecs::Confluent.new #(confluent_config)
  end

  context "#decode" do
    it "should return an LogStash::Event from avro data" do
      schema = Avro::Schema.parse(test_schema)
      dw = Avro::IO::DatumWriter.new(schema)
      buffer = StringIO.new
      buffer.write(MAGIC_BYTE.chr)
      buffer.write([test_schema_id].pack('N'))

      encoder = Avro::IO::BinaryEncoder.new(buffer)
      dw.write(test_event.to_hash, encoder)

      subject.decode(buffer.string) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["foo"] } == test_event["foo"]
        insist { event["bar"] } == test_event["bar"]
      end
    end
  end

  context "#encode" do
    it "should return avro data from a LogStash::Event" do
      got_event = false
      subject.on_event do |event, data|
        schema = Avro::Schema.parse(test_schema)
        datum = StringIO.new(data)

        magic_byte = datum.read(1).unpack('C').first
        schema_id = datum.read(4).unpack('N')[0]

        decoder = Avro::IO::BinaryDecoder.new(datum)
        datum_reader = Avro::IO::DatumReader.new(schema)
        record = datum_reader.read(decoder)

        insist { magic_byte } == 0x0
        insist { schema_id } == test_schema_id
        insist { record["foo"] } == test_event["foo"]
        insist { record["bar"] } == test_event["bar"]
        insist { event.is_a? LogStash::Event }
        got_event = true
      end
      subject.encode(test_event_with_schema)
      insist { got_event }
    end
  end
end