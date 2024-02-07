class AutocompleteInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options)
    set_html_options

    translate_option options, :prompt

    input_html_options[:data] ||= {}
    input_html_options[:data]["autocomplete-target"] = "hidden"
    input_html_options[:type] = "hidden"

    # abort wrapper_options.inspect

    if options[:multiple]
      input_html_options[:value] = ""
      input_html_options[:name] = object.model_name.singular+"["+attribute_name.to_s+"][]" 
    end

    url = options[:url]

    div_data = { controller: "autocomplete", 
                 'autocomplete-url-value': url, 
                 'autocomplete-text-value': association_label,
                 'autocomplete-cancel-icon-value': cancel_icon }
    div_data[:action] = "click->autocomplete#onInputFocus"
    div_data[:action] += " #{options[:action]}" if options[:action]
    div_data[:action] = div_data[:action].strip
    div_data = div_data.merge(options[:data]) unless options[:data].nil?
    if options[:prefetch].present? || url.nil?
      div_data["autocomplete-prefetch-value"] = true
    end

    if options[:multiple].present?
      div_data["autocomplete-multiple-value"] = true
    end

    root_classes = ["autocomplete form-select"]
    root_classes << wrapper_options[:error_class] if has_errors?
    root_classes.push("form-select-sm") if input_html_options[:class].include? "input-sm"

    template.content_tag :div, class: root_classes, data: div_data do
      input = super(wrapper_options) # leave StringInput do the real rendering
      input + current_option + results_ul
    end
  end

  def association_label
    return nil if options[:multiple]
    if !object.nil? && !reflection.nil? && !object.send(reflection.name).nil?
      #  object.send(attribute_name).id
      object.send(reflection.name).to_s
    elsif !options[:collection].nil? && !value.nil?
      options[:collection].where(id: value).first.to_s
    end
  end

  def association_html
    if !object.nil? && !reflection.nil? && !object.send(reflection.name).nil?
      #  object.send(attribute_name).id
      o = object.send(reflection.name)
      if o.class.name == "ActiveRecord::Associations::CollectionProxy"
        mn = o.model_name.plural
      else
        mn = o.model_name.plural
        mn = o.class.base_class.model_name.plural if o.class.base_class != o.class
      end
      begin
        if object.send(reflection.name).class.name == "ActiveRecord::Associations::CollectionProxy"
          object.send(reflection.name).collect do |r| 
            i = "<input type=\"hidden\" name=\"#{object.model_name.singular}[#{attribute_name.to_s}][]\" value=\"#{r.id}\">"
            (template.render("#{mn}/autocomplete_item", item: r)+i.html_safe).html_safe
          end
        else
          template.render("#{mn}/autocomplete_item", item: object.send(reflection.name))
        end
      rescue StandardError
        association_label
      end
    elsif !options[:collection].nil? && !value.nil?

      # We cannot find object as association
      # We will try to search in collection
      items = options[:collection].where(id: value).to_a

      if items[0].nil?
        return association_label
      end
      
      mn = items[0].model_name.plural
      mn = items[0].class.base_class.model_name.plural if items[0].class.base_class != items[0].class

      begin

        return items.collect do |r| 
          i = "<input type=\"hidden\" name=\"#{object.model_name.singular}[#{attribute_name.to_s}][]\" value=\"#{r.id}\">"
          (template.render("#{mn}/autocomplete_item", item: r)+i.html_safe).html_safe
        end

        template.render("#{mn}/autocomplete_item", item: item)
      rescue StandardError
        association_label
      end
    end
  end

  def input_html_classes
    super.push '' # 'form-control'
  end

  private

  # Drawing prefetched results
  def results_ul

    # Using collection as prefetched values if there is no URL
    options[:prefetched] = options[:collection] if options[:url].blank?

    template.content_tag :ul, class: 'list-group text-start', data: { 'autocomplete-target': "results" }, hidden: true do
      if !options[:prefetched].nil?
        # Rendering collection

        o = options[:prefetched].model
        mn = o.model_name.plural
        mn = o.base_class.model_name.plural if o.base_class != o

        template.capture do
          options[:prefetched].each do |item|
            o = template.autocomplete_option(item, label: "to_label", id: options[:value_method]) do
              template.render("#{mn}/autocomplete_item", item: item)
            rescue StandardError
              item.to_s
            end

            template.concat o
          end
        end

      else
        template.content_tag :li, I18n.t("autocomplete.type_first_letters"), class: "list-group-item hint", "aria-disabled": true
      end
    end
  end

  def cancel_icon
    return "fa fa-times-circle" if TurboAutocomplete.configuration.icons_framework == :fa
    return "bi bi-x-circle-fill" if TurboAutocomplete.configuration.icons_framework == :bi    
  end

  def current_option
    template.content_tag :div, class: 'current-options' do
      template.capture do

        # abort association_html.inspect

        items = association_html
        items = [items] if !items.kind_of?(Array)
        items = items.compact

        co = ""

        # Placeholder for options
        items.each do |ah|
          co += ah.nil? ? "" : ('<span class="current-option d-flex" data-autocomplete-target="current"><div class="nowrap current-value overflow-hidden text-truncate">'+ah+'</div><i class="ps-1 d-block cancel '+cancel_icon+'" data-action="click->autocomplete#cancel"></i></span>').html_safe
        end

        template.concat ('<span data-autocomplete-target="selection" class="selection">'+co+'</span>').html_safe

        # if options[:prompt].present?
        template.concat template.content_tag(:span, (options[:prompt].presence || "Select..."), class: "prompt")
        # end

        template.concat(visible_input)
      end
    end
  end

  def visible_input
    template.content_tag :input, type: 'text', class: ["visible-input"], value: "",
                                 data: { 'autocomplete-target': "input" } do
    end
  end

  def set_html_options; end

  def value
    v = object.send(attribute_name) if object.respond_to?(attribute_name) || object.is_a?(Ransack::Search)
    v = v.to_date rescue v = nil if v.is_a?(String)
    v
  end

  def translate_option(options, key)
    if options[key] == :translate
      namespace = key.to_s.pluralize

      options[key] = translate_from_namespace(namespace, true)
    end
  end
end
