# TurboAutocomplete

Modern simple_form autocomplte input based on Stimulus and Turbo for Rails 7 apps

## Installation

* Add helpers to your application controller: ```helper TurboAutocomplete::Engine.helpers```
* Add NPM module ```turbo_autocomplete```
* Add CSS: ```@import 'turbo_auticomplete/app/assets/stylesheets/turbo_auticomplete/application.scss';```
* Add JS: ```import AutocompleteController from "turbo_autocomplete/app/javascript/controllers/autocomplete.js"; application.register("autocomplete", AutocompleteController)```

## Usage

Gem provides helpers for remote-backed autocompleting and simple_form input field.

## Form input

  = f.association :user, as: :autocomplete

### Non-association attributes

Use input instead association and provide collection to help input to recognize what objects to look for:

  = f.input :user_ids, as: :autocomplete, collection: User.all

Collection from here will only be used to render selected option. It will not be used for options loading

### Prefetch

Use ```prefetched``` option to render some options before use interacted with select

  = f.association :user, as: :autocomplete, prefetched: User.all

Use ```prefetch``` switch to tell autocomplete load values from URL after user interacted the select

  = f.association :user, as: :autocomplete, prefetch: true

### Multiple

Set ```multiple``` option to true to allow multiple values selection for your has_many associations

  = f.association :users, as: :autocomplete, multiple: true

## Server-side search

This will be enabled when you pass ```url``` option:

  = f.association :user, as: :autocomplete, url: search_users_path(q: {logo_cont: "[query]"})

Use magic "[query]" param to help gem to add typed search param to your search controller request.

You also can use ```index``` action for searching as well as displaying lists in your application by using Rails view variants feature.

This gem provides set of helpers for easier search responses generation.

Common case of searchable ```index.haml``` described below:

  = autocomplete(@users) do |user|
    = autocomplete_option(user) do
      = render "autocomplete_item", item: user

You need to have ```users/_autocomplete_item.haml``` view:

  %i.fa.fa-user
  = item.logo

Always use ```item``` variable for this partial

## Credits

Inspired by and based on Stimulus-Autocomplete https://github.com/afcapel/stimulus-autocomplete
