module TurboAutocomplete
  module ApplicationHelper

    def autocomplete(collection, limit: 20, &block)

      # To ensure limitations for performance
      collection = collection.limit(limit)
  
      if collection.length.zero?
        # content_tag(:button, t("not_found"), class: %w[list-group-item list-group-item-action disabled], data: {message: "autocomplete_no_options_found"})
        content_tag(:button, t("not_found"), class: %w[dropdown-item dropdown-item-action disabled], data: {message: "autocomplete_no_options_found"})
      else
  
        capture do
          collection.each(&block)
        end
  
      end
    end
  
    def autocomplete_option(option, label: "logo", id: "id", data: {}, oneliner: true, &block)
      id = "id" if id.nil?

      out_data = {
        'autocomplete-value': option.send(id).to_s,
        'autocomplete-label': option.send(label),
        'autocomplete-model': option.model_name.to_s
      }

      out_data = out_data.merge(data)
  
      m = "#{option.model_name.singular}_autocomplete_data"
      out_data = out_data.merge(send(m, option)) if self.class.method_defined?(m)

      # classes = %w[list-group-item list-group-item-action]
      classes = %w[dropdown-item dropdown-item-action]

      if oneliner
        classes += %w[overflow-x-hidden text-truncate oneliner]
      else
        classes += %w[multiliner]
      end

      content_tag(
        :span,
        class: classes,
        role: "option",
        data: out_data,
        &block
      )
    end

  end
end
