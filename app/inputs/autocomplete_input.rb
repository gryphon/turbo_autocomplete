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

    if options[:polymorphic]
      input_html_options[:value] = object.send(attribute_name)&.id
      input_html_options[:name] = "#{object_name}[#{attribute_name}_id]" 
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

    root_classes = ["turbo-autocomplete form-select"]
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
    elsif (!options[:collection].nil? || options[:polymorphic]) && !value.nil?
      if options[:polymorphic]
        value.to_s
      else
        if options[:collection].respond_to?(:where)
          options[:collection].where(options[:value_method] => value).first.to_s
        else
          options[:collection].find{|i| i.send(options[:value_method]) == value}&.to_s
        end
      end
    end
  end

  def association_html

    # This is regular association with reflection passed
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
            (template.render(autocomplete_item_template(mn), item: r)+i.html_safe).html_safe
          end
        else
          template.render(autocomplete_item_template(mn), item: object.send(reflection.name))
        end
      rescue StandardError
        association_label
      end
    elsif (!options[:collection].nil? || options[:polymorphic]) && !value.nil?

      if options[:polymorphic]
        items = [object.send(attribute_name)]
      else
        # We cannot find object as association
        # We will try to search in collection
        
        if options[:collection].respond_to?(:where)
          items = options[:collection].where(options[:value_method] => value).to_a
        else
          items = options[:collection].find{|i| i.send(options[:value_method]) == value}
        end
      end

      if items[0].nil?
        return association_label
      end
      
      mn = items[0].model_name.plural
      mn = items[0].class.base_class.model_name.plural if items[0].class.base_class != items[0].class

      begin

        return items.collect do |r| 
          i = "<input type=\"hidden\" name=\"#{object.model_name.singular}[#{attribute_name.to_s}][]\" value=\"#{r.id}\">"
          (template.render(autocomplete_item_template(mn), item: r)+i.html_safe).html_safe
        end

        template.render(autocomplete_item_template(mn), item: item)
      rescue StandardError
        association_label
      end
    end
  end

  def input_html_classes
    super.push '' # 'form-control'
  end

  private

  def autocomplete_item_template mn
    namespace = (template.controller.class.module_parent == Object) ? nil : template.controller.class.module_parent.to_s.underscore.to_sym
    return "#{namespace}/#{mn}/autocomplete_item" if template.lookup_context.exists?("autocomplete_item", ["#{namespace}/#{mn}"], true)
    "#{mn}/autocomplete_item"
  end

  # Drawing prefetched results
  def results_ul

    # Using collection as prefetched values if there is no URL
    options[:prefetched] = options[:collection] if options[:url].blank?

    # template.content_tag :ul, class: 'list-group text-start', data: { 'autocomplete-target': "results" }, hidden: true do
    template.content_tag :ul, class: 'dropdown-menu show text-start', data: { 'autocomplete-target': "results" }, hidden: true do
      if !options[:prefetched].nil?
        # Rendering collection

        template.capture do
          options[:prefetched].each do |item|

            o = item.class
            mn = o.model_name.plural
            mn = o.base_class.model_name.plural if o.base_class != o

            o = template.render(autocomplete_item_template(mn), item: item, options: options.slice(:value_method))# rescue item.to_s
            template.concat o
          end
        end

      else
        template.content_tag :li, I18n.t("autocomplete.type_first_letters"), class: "dropdown-item hint", "aria-disabled": true
        # template.content_tag :li, I18n.t("autocomplete.type_first_letters"), class: "list-group-item hint", "aria-disabled": true
      end
    end
  end

  def cancel_icon
    return "fa fa-times-circle" if TurboAutocomplete.configuration.icons_framework == :fa
    return "bi bi-x-circle-fill" if TurboAutocomplete.configuration.icons_framework == :bi    
    return "ti ti-circle-x" if TurboAutocomplete.configuration.icons_framework == :ti    
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
          co += ah.nil? ? "" : ('<span class="current-option d-flex" data-autocomplete-target="current">'+ah.to_s+'<i class="ps-1 d-block cancel '+cancel_icon+'" data-action="click->autocomplete#cancel"></i></span>').html_safe
        end

        template.concat(('<span data-autocomplete-target="selection" class="selection">'+co+'</span>').html_safe)

        # if options[:prompt].present?
        template.concat template.content_tag(:span, (options[:prompt].presence || I18n.t("autocomplete.select")), class: "prompt")
        # end

        template.concat(visible_input)
        # abort visible_input.inspect

        template.concat(model_input)
      end
    end
  end

  def visible_input
    template.content_tag :input, type: 'text', class: ["visible-input"], value: "",
                                 data: { 'autocomplete-target': "input" } do
    end
  end

  def model_input 
    return nil if !options[:polymorphic]
    v = object.send(attribute_name)&.model_name
    template.content_tag :input, name: "#{object_name}[#{attribute_name}_type]", disabled: v.blank?, type: 'hidden', value: v,
                                 data: { 'autocomplete-target': "model" } do
    end
  end

  def set_html_options; end

  def value
    v = object.send(attribute_name) if object.respond_to?(attribute_name) || object.is_a?(Ransack::Search)
    v = v.to_date rescue v = nil if v.is_a?(String)
    # return v&.id if options[:polymorphic]
    v
  end

  def translate_option(options, key)
    if options[key] == :translate
      namespace = key.to_s.pluralize

      options[key] = translate_from_namespace(namespace, true)
    end
  end
end
