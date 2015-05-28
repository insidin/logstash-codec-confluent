# encoding: utf-8
require "avro"
require "logstash/codecs/base"
require "logstash/event"
require "logstash/timestamp"
require "logstash/util"
require "logstash-codec-confluent_jars.rb"

MAGIC_BYTE = 0x0

# Codec to encode/decode the confluent.io avro format
# When encoding, expects an avro schema (field @schema) as part of the event metadata
class LogStash::Codecs::Confluent < LogStash::Codecs::Base
  config_name "confluent"

  # schema repository base uri
  # if not set, default uses a local schema registry (see io.confluent.kafka.schemaregistry.client.LocalSchemaRegistryClient)
  config :schema_registry_url, :validate => :string, :required => false

  # include the schema info as part of the event metadata when decoding
  # if set, adds @schema_id and @schema fields to event @metadata
  config :incl_schema_metadata, :validate => :boolean, :required => false, :default => false

  def read_schema(id)
    @client.getByID(id).toString()
  end

  # Registers the Avro json schema in the SchemaRegistry, and returns its id
  # Todo: add some caching here? The SchemaRegistry does some caching, but the schema still needs to be parsed to a Schema object here
  def register_schema(schema)
    s = Java::org.apache.avro.Schema.parse(schema)
    @client.register(s.getName, s)
  end

  # Returs and Avro::Schema
  def schema_to_object(schema)
    Avro::Schema.parse(schema)
  end

  public
  def register
    if (schema_registry_url != nil)
      @client = Java::io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.new(schema_registry_url, 1000)
    else
      @client = Java::io.confluent.kafka.schemaregistry.client.LocalSchemaRegistryClient.new
    end
  end

  public
  def decode(data)
    datum = StringIO.new(data)
    magic_byte = datum.read(1).unpack('C').first

    if (magic_byte != MAGIC_BYTE)
      raise "Unknown magic byte!"
    end

    schema_id = datum.read(4).unpack('N')[0]
    schema = read_schema(schema_id)
    avro_schema = schema_to_object(schema)
    decoder = Avro::IO::BinaryDecoder.new(datum)
    datum_reader = Avro::IO::DatumReader.new(avro_schema)
    event_data = datum_reader.read(decoder)

    if (incl_schema_metadata)
      event_data["@metadata"] = {"@schema_id" => schema_id, "@schema" => schema}
    end
    event = LogStash::Event.new(event_data)

    yield event
  end

  public
  def encode(event)
    schema = event["@metadata"]["@schema"]

    if (schema == nil)
      raise "Avro schema required (as event @metadata)"
    end

    schema_id = register_schema(schema)
    avro_schema = schema_to_object(schema)

    buffer = StringIO.new
    buffer.write(MAGIC_BYTE.chr)
    buffer.write([schema_id].pack('N'))

    encoder = Avro::IO::BinaryEncoder.new(buffer)
    datum_writer = Avro::IO::DatumWriter.new(avro_schema)
    datum_writer.write(event.to_hash, encoder)
    @on_event.call(event, buffer.string)
  end
end
