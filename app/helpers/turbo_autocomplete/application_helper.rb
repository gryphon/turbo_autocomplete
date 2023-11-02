module TurboAutocomplete
  module ApplicationHelper

    def autocomplete(collection, &block)

      # To ensure limitations for performance
      collection = collection.limit(20)
  
      if collection.length.zero?
        content_tag(:button, t("not_found"), class: %w[list-group-item list-group-item-action disabled], data: {message: "autocomplete_no_options_found"})
      else
  
        capture do
          collection.each(&block)
        end
  
      end
    end
  
    def autocomplete_option(option, label: "logo", id: "id", data: {}, &block)
      id = "id" if id.nil?
      out_data = {
        'autocomplete-value': option.send(id),
        'autocomplete-label': option.send(label)
      }
  
      out_data = out_data.merge(data)
  
      m = "#{option.model_name.singular}_autocomplete_data"
      out_data = out_data.merge(send(m, option)) if self.class.method_defined?(m)
  
      content_tag(
        :button,
        class: %w[list-group-item list-group-item-action],
        role: "option",
        data: out_data,
        &block
      )
    end
  
    def bank_autocomplete_data(bank)
      { currency: bank.currency.code }
    end
  

  end
end
