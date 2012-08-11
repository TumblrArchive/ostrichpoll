require 'ostrichpoll/ostrich_validator.rb'

include OstrichPoll

describe Host do
  sample_map = {
      'l1' => {
          'l2' => {
              'has/slash' => 4,
              'l3' => 5
          },
          'l4' => 15,
          'l5' => 16,
          'l6' => 17
      }
  }
  h = Host.new

  it 'will fail gracefully' do
    h.find_value(sample_map, 'invalidkey').should be_nil
  end

  it 'supports simple key matching' do
    h.find_value(sample_map, 'l1').should be_a_kind_of(Hash)

    h.find_value(sample_map, 'l1/l2').should be_a_kind_of(Hash)
    h.find_value(sample_map, 'l1/l4').should eq(15)
    h.find_value(sample_map, 'l1/l5').should eq(16)
    h.find_value(sample_map, 'l1/l6').should eq(17)
  end

  it 'supports regexp key matching' do
    h.find_validation_names_by_regex(sample_map, 'l1/l?').should eq(
      %w{l1/l2/has/slash l1/l2/l3 l1/l4 l1/l5 l1/l6}
    )
  end

  it 'supports escaped slashes' do
    h.split_on_slash('a/b/c/d').should eq(%w[a b c d])
    h.split_on_slash('a\\/b/c/d').should eq(%w[a/b c d])
    h.split_on_slash('a/b/c/d', 2).should eq(%w[a b/c/d])
  end
end