require 'spec_helper'

class UnPaginatedAPI < Grape::API
  # Intentionally not including Grape::Kaminari
end

class PaginatedAPI < Grape::API
  include Grape::Kaminari
end

describe Grape::Kaminari do

  describe 'unpaginated api' do
    subject { Class.new(UnPaginatedAPI) }

    it 'raises an error' do
      expect { subject.paginate }.to raise_error(NoMethodError, /undefined method `paginate' for/i)
    end
  end

  describe 'default paginated api' do
    subject { Class.new(PaginatedAPI) }

    it 'adds to declared parameters' do
      subject.paginate
      if Grape::Kaminari.post_0_9_0_grape?
        expect(subject.inheritable_setting.route[:declared_params]).to eq([{:page=>[:number, :size, :offset]}])
      else
        expect(subject.settings[:declared_params]).to eq([{:page=>[:number, :size, :offset]}])
      end
    end

    describe 'descriptions, validation, and defaults' do
      before do
        subject.paginate
        subject.get '/' do; end
      end
      let(:params) {subject.routes.first.route_params}

      it 'does not require :page' do
        expect(params['page'][:required]).to eq(false)
      end

      it 'does not require page[number]' do
        expect(params['page[number]'][:required]).to eq(false)
      end

      it 'does not require page[size]' do
        expect(params['page[size]'][:required]).to eq(false)
      end

      it 'does not require page[offset]' do
        expect(params['page[offset]'][:required]).to eq(false)
      end

      it 'describes page[number]' do
        expect(params['page[number]'][:desc]).to eq('Page offset to fetch.')
      end

      it 'describes page[size]' do
        expect(params['page[size]'][:desc]).to eq('Number of results to return per page.')
      end

      it 'describes page[offset]' do
        expect(params['page[offset]'][:desc]).to eq('Pad a number of results.')
      end

      it 'validates :page as Hash' do
        expect(params['page'][:type]).to eq('Hash')
      end

      it 'validates page[number] as Integer' do
        expect(params['page[number]'][:type]).to eq('Integer')
      end

      it 'validates page[size] as Integer' do
        expect(params['page[size]'][:type]).to eq('Integer')
      end

      it 'validates page[offset] as Integer' do
        expect(params['page[offset]'][:type]).to eq('Integer')
      end

      it 'defaults page[number] to 1' do
        expect(params['page[number]'][:default]).to eq(1)
      end

      it 'defaults page[size] to Kaminari.config.default_per_page' do
        expect(params['page[size]'][:default]).to eq(::Kaminari.config.default_per_page)
      end

      it 'defaults page[offset] to 0' do
        expect(params['page[offset]'][:default]).to eq(0)
      end
    end

  end

  describe 'custom paginated api' do
    subject { Class.new(PaginatedAPI) }
    def app; subject; end

    before do
      subject.paginate page: {size: 99, max_size: 999, offset: 9}
      subject.get '/' do; end
    end
    let(:params) {subject.routes.first.route_params}

    it 'defaults page[size] to customized value' do
      expect(params['page[size]'][:default]).to eq(99)
    end

    it 'succeeds when page[size] is within :max_value' do
      get('/', page: {number: 1, size: 999})
      expect(last_response.status).to eq 200
    end

    it 'ensures page[size] is within :max_value' do
      get('/', page: {number: 1, size: 1_000})
      expect(last_response.status).to eq 400
      expect(last_response.body).to match /page\[size\] must be less than 999/
    end

    it 'defaults page[offset] to customized value' do
      expect(params['page[offset]'][:default]).to eq(9)
    end

  end

  describe 'paginated api without page[offset]' do
    subject { Class.new(PaginatedAPI) }

    it 'excludes page[offset] from declared params' do
      subject.paginate page: {offset: false}
      if Grape::Kaminari.post_0_9_0_grape?
        expect(subject.inheritable_setting.route[:declared_params].first[:page]).not_to include(:offset)
      else
        expect(subject.settings[:declared_params].first[:page]).not_to include(:offset)
      end
    end

  end

end
