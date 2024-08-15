# frozen_string_literal: true

RSpec.describe LeveledCache::Store do
  shared_examples "suite" do
    let(:key) { "foo" }
    let(:val) { "bar" }

    it "can instantiate using the ActiveSupport shorthand syntax" do
      c = ActiveSupport::Cache.lookup_store(:leveled_cache_store, outer, inner)
      expect(c).to be_a(described_class)
    end

    describe "#fetch" do
      it "populates all levels with the contents of a block" do
        expect(cache.fetch(key) { val }).to eq(val)
        expect(inner.fetch(key)).to eq(val)
        expect(middle.fetch(key)).to eq(val)
        expect(outer.fetch(key)).to eq(val)
      end

      it "populates outer levels from the first populated inner level" do
        cache.fetch(key) { val }
        outer.delete(key)

        expect(inner).not_to receive(:fetch)
        expect(cache.fetch(key)).to eq(val)
      end
    end

    describe "#fetch_multi" do
      let(:entries) { {"k1" => "v1", "k2" => "v2"} }

      it "populates all levels from the contents of a block" do
        vals = cache.fetch_multi(*entries.keys) do |k|
          entries.fetch(k)
        end

        expect(vals).to eq(entries)
        expect(outer.read_multi(*entries.keys)).to eq(entries)
        expect(middle.read_multi(*entries.keys)).to eq(entries)
        expect(inner.read_multi(*entries.keys)).to eq(entries)
      end

      it "populates outer levels from the first populated inner level" do
        middle.write_multi(entries)

        expect(inner).not_to receive(:read_multi)

        vals = cache.fetch_multi(*entries.keys) do |k|
          entries.fetch(k)
        end

        expect(vals).to eq(entries)
        expect(outer.read_multi(*entries.keys)).to eq(entries)
      end

      it "only populates missing keys from inner levels" do
        outer.write("k1", entries["k1"])

        expect(inner).to receive(:read_multi).with("k2").and_call_original

        vals = cache.fetch_multi(*entries.keys) do |k|
          entries.fetch(k)
        end

        expect(vals).to eq(entries)
      end
    end

    describe "#write" do
      it "writes to all levels" do
        cache.write(key, val)

        expect(cache.read(key)).to eq(val)
        expect(inner.read(key)).to eq(val)
        expect(middle.read(key)).to eq(val)
        expect(outer.read(key)).to eq(val)
      end

      it "returns an array of responses from underlying caches" do
        expect(cache.write(key, val).flatten).to contain_exactly(true, true, true)
      end
    end

    describe "#read" do
      it "reads the first populated value" do
        cache.write(key, val)
        outer.delete(key)

        expect(inner).not_to receive(:read)
        expect(cache.read(key)).to eq(val)
      end

      it "reads values populated directly to the underlying caches" do
        inner.write(key, val)
        expect(cache.read(key)).to eq(val)
      end

      it "returns nil if a value isn't present in any caches" do
        expect(cache.read("missing")).to be_nil
      end
    end

    describe "#delete" do
      it "deletes from all levels" do
        cache.write(key, val)
        expect(cache.read(key)).to eq(val)

        cache.delete(key)
        expect(cache.read(key)).to be_nil
        expect(inner.read(key)).to be_nil
        expect(middle.read(key)).to be_nil
        expect(outer.read(key)).to be_nil
      end

      it "does not double namespace keys" do
        args = {namespace: "ns"}
        cache.write(key, val, **args)
        expect(cache.read(key, **args)).to eq(val)

        cache.delete(key, **args)
        expect(cache.read(key, **args)).to be_nil
      end

      it "returns an array of responses from underlying caches" do
        expect(cache.delete(key).flatten).to contain_exactly(false, false, false)
      end
    end

    describe "#read_multi" do
      let(:entries) { {"k1" => "v1", "k2" => "v2", "k3" => "v3"} }

      it "reads each key from the first populated level" do
        entries.zip([outer, middle, inner]).each do |(k, v), c|
          c.write(k, v)
        end

        expect(middle).to receive(:read_multi).with("k2", "k3").and_call_original
        expect(inner).to receive(:read_multi).with("k3").and_call_original
        expect(cache.read_multi(*entries.keys)).to eq(entries)
      end
    end

    describe "#write_multi" do
      let(:entries) { {"k1" => "v1", "k2" => "v2", "k3" => "v3"} }

      it "writes to all levels" do
        cache.write_multi(entries)

        expect(cache.read_multi(*entries.keys)).to eq(entries)
        expect(inner.read_multi(*entries.keys)).to eq(entries)
        expect(middle.read_multi(*entries.keys)).to eq(entries)
        expect(outer.read_multi(*entries.keys)).to eq(entries)
      end
    end
  end

  let(:klass) { ActiveSupport::Cache::MemoryStore }
  let(:outer) { klass.new(namespace: "outer") }
  let(:middle) { klass.new(namespace: "middle") }
  let(:inner) { klass.new(namespace: "inner") }

  context "one level" do
    subject(:cache) { described_class.new(outer, middle, inner) }
    include_examples "suite"
  end

  context "two levels" do
    subject(:cache) { described_class.new(outer, described_class.new(middle, inner)) }
    include_examples "suite"
  end

  context "nested levels" do
    subject(:cache) { described_class.new(outer, described_class.new(middle, described_class.new(inner))) }
    include_examples "suite"
  end
end
