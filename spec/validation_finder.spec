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

  it 'should fail gracefully' do
    h.find_value(sample_map, 'invalidkey').should be_nil
  end

  it 'support simple key matching' do
    h.find_value(sample_map, 'l1').should be_a_kind_of(Hash)

    h.find_value(sample_map, 'l1/l2').should be_a_kind_of(Hash)
    h.find_value(sample_map, 'l1/l4').should eq(15)
    h.find_value(sample_map, 'l1/l5').should eq(16)
    h.find_value(sample_map, 'l1/l6').should eq(17)
  end
end