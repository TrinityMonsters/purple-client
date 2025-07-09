require 'spec_helper'

RSpec.describe 'README examples' do
  before do
    stub_const('StoreEvent', Class.new do
      def self.call(**args); end
    end)

    stub_const('SomeModel', Class.new do
      def self.find(id)
        id
      end
    end)
  end

  let(:executed) { [] }

  before do
    allow_any_instance_of(Purple::Path).to receive(:execute) do |instance, params = {}, kw_args = {}, *callback_args|
      executed << { path: instance.full_path, params: params, kw_args: kw_args, callback_args: callback_args }
      :ok
    end
  end

  after do
    %i[StatusClient JobsClient ProfileClient CustomHeadersClient PostsClient EventsClient AccountsClient CalendarClient].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  it 'evaluates code snippets from README' do
    readme = File.read(File.expand_path('../README.md', __dir__))
    snippets = readme.scan(/```ruby(.*?)```/m).map { |m| m.first.strip }
    snippets.each do |code|
      expect { eval(code) }.not_to raise_error
    end

    expect(executed).to include(hash_including(path: 'status'))
    expect(executed).to include(hash_including(path: 'jobs/123'))
    expect(executed).to include(hash_including(path: 'profile'))
    expect(executed).to include(hash_including(path: 'widgets'))
    expect(executed).to include(hash_including(path: 'users/7/posts'))
    expect(executed).to include(hash_including(path: 'events'))
    expect(executed).to include(hash_including(path: 'schedule'))
  end
end
