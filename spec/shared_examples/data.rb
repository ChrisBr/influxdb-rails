require "spec_helper"

RSpec.shared_examples_for "with additional data" do |series_names|
  context "values" do
    let(:additional_values) do
      { another: :value }
    end

    after do
      InfluxDB::Rails.current.reset
    end

    it "does include the tags" do
      InfluxDB::Rails.current.values = additional_values

      series_names.each do |series_name|
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, hash_including(values: hash_including(another: :value)))
      end

      subject.call("unused", start, finish, "unused", payload)
    end
  end

  context "tags" do
    context "when tags_middleware is overwritten" do
      before do
        allow(config).to receive(:tags_middleware).and_return(tags_middleware)
      end

      let(:tags_middleware) { ->(tags) { tags.merge(static: "value", nil: nil, empty: "") } }

      it "processes tags throught the middleware" do
        tags = data[:tags].merge(static: "value")

        series_names.each do |series_name|
          expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, include(tags: tags))
        end

        subject.call("unused", start, finish, "unused", payload)
      end
    end

    context "when tags are set in the current context" do
      let(:input) do
        { another: :value, nil: nil, empty: "" }
      end
      let(:output) do
        { another: :value }
      end

      after do
        InfluxDB::Rails.current.reset
      end

      it "does include the tags" do
        InfluxDB::Rails.current.tags = input
        tags = data[:tags].merge(output)

        series_names.each do |series_name|
          expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, include(tags: tags))
        end

        subject.call("unused", start, finish, "unused", payload)
      end
    end
  end
end
