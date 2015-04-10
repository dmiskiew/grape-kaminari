require "grape/kaminari/version"
require "grape/kaminari/max_value_validator"
require "kaminari/grape"

module Grape
  module Kaminari
    def self.included(base)
      base.class_eval do
        helpers do
          def paginate(collection)
            collection.page(params[:page][:number]).per(params[:page][:size]).padding(params[:page][:offset]).tap do |data|
              header "X-Total",       data.total_count.to_s
              header "X-Total-Pages", data.num_pages.to_s
              header "X-Per-Page",    params[:page][:size].to_s
              header "X-Page",        data.current_page.to_s
              header "X-Next-Page",   data.next_page.to_s
              header "X-Prev-Page",   data.prev_page.to_s
              header "X-Offset",      params[:page][:offset].to_s
            end
          end
        end

        def self.paginate(options = {})
          options[:page] ||= {}
          options[:page].reverse_merge!(
            size: ::Kaminari.config.default_per_page || 10,
            max_size: ::Kaminari.config.max_per_page,
            offset: 0
          )
          params do
            optional :page, type: Hash do
              optional :number,
                       type: Integer,
                       default: 1,
                       desc: 'Page offset to fetch.'
              optional :size,
                       type: Integer,
                       default: options[:page][:size],
                       desc: 'Number of results to return per page.',
                       max_value: options[:page][:max_size]
              if options[:page][:offset].is_a? Numeric
                optional :offset,
                         type: Integer,
                         default: options[:page][:offset],
                         desc: 'Pad a number of results.'
              end
            end
          end
        end
      end
    end
  end
end
