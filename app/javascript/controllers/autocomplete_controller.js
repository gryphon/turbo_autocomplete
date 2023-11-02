import { Controller } from "@hotwired/stimulus"

const optionSelector = "[role='option']:not([aria-disabled])"
const activeSelector = "[aria-selected='true']"

export default class Autocomplete extends Controller {
  static targets = ["input", "hidden", "results", "current", "selection"]
  static classes = ["selected"]
  static values = {
    ready: Boolean,
    multiple: Boolean,
    submitOnEnter: Boolean,
    url: String,
    params: Object, // Additional params to be passed to search query
    prefetch: Boolean, // Says to prefetch results on connect
    minLength: Number,
    opened: {type: Boolean, default: false},
    text: String
  }

  connect() {
    this.close()

    if(!this.inputTarget.hasAttribute("autocomplete")) this.inputTarget.setAttribute("autocomplete", "off")
    this.inputTarget.setAttribute("spellcheck", "false")

    this.mouseDown = false

    this.onInputChange = debounce(this.onInputChange, 300)

    this.inputTarget.addEventListener("keydown", this.onKeydown)
    this.inputTarget.addEventListener("blur", this.onInputBlur)
    this.inputTarget.addEventListener("focus", this.onInputFocus)
    this.inputTarget.addEventListener("input", this.onInputChange)
    this.resultsTarget.addEventListener("mousedown", this.onResultsMouseDown)
    this.resultsTarget.addEventListener("click", this.onResultsClick)

    if (this.inputTarget.hasAttribute("autofocus")) {
      this.inputTarget.focus()
    }

    if (this.multipleValue) {
      this.hiddenTarget.classList.add("d-none")
    }

    this.readyValue = true
  }

  disconnect() {

    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("keydown", this.onKeydown)
      this.inputTarget.removeEventListener("blur", this.onInputBlur)
      this.inputTarget.removeEventListener("input", this.onInputChange)
    }

    if (this.hasResultsTarget) {
      this.resultsTarget.removeEventListener("mousedown", this.onResultsMouseDown)
      this.resultsTarget.removeEventListener("click", this.onResultsClick)
    }
  }

  openedValueChanged() {
    console.log("Opened Value Changed", this.openedValue)
    if (this.openedValue) this.focus();
  }

  sibling(next) {
    const options = this.options
    const selected = this.selectedOption
    const index = options.indexOf(selected)
    const sibling = next ? options[index + 1] : options[index - 1]
    const def = next ? options[0] : options[options.length - 1]
    return sibling || def
  }

  select(target) {

    const previouslySelected = this.selectedOption
    if (previouslySelected) {
      previouslySelected.removeAttribute("aria-selected")
      previouslySelected.classList.remove(...this.selectedClassesOrDefault)
    }

    target.setAttribute("aria-selected", "true")
    target.classList.add(...this.selectedClassesOrDefault)
    this.inputTarget.setAttribute("aria-activedescendant", target.id)
    target.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  onKeydown = (event) => {
    const handler = this[`on${event.key}Keydown`]
    if (handler) handler(event)
  }

  onEscapeKeydown = (event) => {
    if (!this.resultsShown) return

    this.hideAndRemoveOptions()
    event.stopPropagation()
    event.preventDefault()
  } 

  onArrowDownKeydown = (event) => {
    const item = this.sibling(true)
    if (item) this.select(item)
    event.preventDefault()
  }

  onArrowUpKeydown = (event) => {
    const item = this.sibling(false)
    if (item) this.select(item)
    event.preventDefault()
  }

  onTabKeydown = (event) => {
    const selected = this.selectedOption
    if (selected) this.commit(selected)
  }

  onEnterKeydown = (event) => {
    console.log("Enter keydown handled")
    const selected = this.selectedOption
    if (selected && this.resultsShown) {
      this.commit(selected)
      if (!this.hasSubmitOnEnterValue) {
        event.preventDefault()
      }
    }
  }

  onInputBlur = () => {
    console.log("Autocomplete -> Input blurred")

    if (this.mouseDown) return

    this.element.classList.remove("focus")

    if (this.hasSelectionTarget) {
      this.selectionTarget.classList.remove("d-none")
    }
    this.inputTarget.value = "" // We now have currentTarget that shows current option
    this.close()
  }

  onInputFocus = (event) => {

    event.stopPropagation();

    // Fixing issue when invoked on form submits
    if (event.constructor.name== "PointerEvent" && event.pointerId == -1) return;

    this.focus();

  }

  focus() {

    this.element.classList.add("focus")

    if (this.prefetchValue && (!this.resultsShown)) {
      this.fetchResults()
    }
    this.inputTarget.value = this.textValue;
    this.inputTarget.select()

    // Opening hint as results for the first time only
    if (this.hasUrlValue && !this.prefetchValue && !this.hintShowed) {
      this.hintShowed = true
      this.open()
    }

    if (this.hasSelectionTarget && !this.multipleValue) {
      this.selectionTarget.classList.add("d-none")
    }
  }

  cancel(event) {
    event.stopPropagation()
    if (this.multipleValue) {
      this.deselect(event.target.closest(".current-option"))
    } else {
      this.commit()
    }
  }

  deselect(item){

    console.log("Autocomplete->deselect", item)
    // this.textValue = ""
    // this.inputTarget.value = ""

    // Making change in item option hidden input

    this.inputTarget.focus()
    this.inputTarget.blur() // TODO: why to focus input here?
    this.hideAndRemoveOptions()

    // Adding visually current option to item
    item.remove()
    
    // Dispatch Stimulus event instead JS
    this.dispatch("select", { detail: { option: null } }) 

  }

  commit(selected) {

    console.log("Autocomplete->commit", selected)

    if (selected) {
      if (selected.getAttribute("aria-disabled") === "true") return

      if (selected instanceof HTMLAnchorElement) {
        selected.click()
        this.close()
        return
      }
    }

    let value = ""

    if (selected) {
      this.textValue = selected.getAttribute("data-autocomplete-label") || selected.textContent.trim()
      value = selected.getAttribute("data-autocomplete-value") || this.textValue
    } else {
      this.textValue = ""
    }
    this.inputTarget.value = ""

    // Making change in selected option hidden input
    if (this.multipleValue) {
      // SelectedOption.addTo(this.selectionTarget, this.hiddenTarget.name, value, "kek")
    } else if (this.hasHiddenTarget) {
      this.hiddenTarget.value = value
      this.hiddenTarget.dispatchEvent(new Event("input"))
      this.hiddenTarget.dispatchEvent(new Event("change"))
    } else {
      this.inputTarget.value = ""
    }

    this.inputTarget.focus()
    this.inputTarget.blur() // TODO: why to focus input here?
    this.hideAndRemoveOptions()

    // Adding visually current option to selected
    if (this.hasSelectionTarget) {
      if (selected) {
        if (!this.multipleValue) {
          // Clearing all options
          this.selectionTarget.innerHTML = null;
        }

        let hidden_option = ''
        if (this.multipleValue) hidden_option = '<input type="hidden" name="'+this.hiddenTarget.getAttribute('name')+'" value="'+value+'">'
        let option = '<span class="current-option" data-autocomplete-target="current">'+hidden_option+selected.innerHTML+'<i class="cancel fa fa-times-circle" data-action="click->autocomplete#cancel"></i></span>'
        this.selectionTarget.insertAdjacentHTML("beforeend", option)
      } else {
        this.selectionTarget.innerHTML = null;
      } 
    }
    
    // this.element.dispatchEvent(
    //   new CustomEvent("autocomplete.change", {
    //     bubbles: true,
    //     detail: { value: value, textValue: textValue, selected: selected }
    //   })
    // )
    // Dispatch Stimulus event instead JS
    this.dispatch("select", { detail: { option: selected } }) 

  }

  clear() {
    this.inputTarget.value = ""
    if (this.hasHiddenTarget) this.hiddenTarget.value = ""
  }

  onResultsClick = (event) => {

    if (! this.resultsShown) return;

    console.log("Results click")

    event.stopPropagation();
    event.preventDefault(); // This is because we have open event processor at the root element

    if (!(event.target instanceof Element)) {
      console.log("autocomplete->resultsClick: not instanceof Element")
      return
    }
    const selected = event.target.closest(optionSelector)
    console.log("autocomplete->resultsClick: selected", selected)

    if (selected) {
      this.commit(selected)
    } else {
      this.close()
    }
  }

  onResultsMouseDown = () => {
    this.mouseDown = true
    this.resultsTarget.addEventListener("mouseup", () => {
      this.mouseDown = false
    }, { once: true })
  }

  onInputChange = () => {
    this.element.removeAttribute("value")
    if (this.hasHiddenTarget) this.hiddenTarget.value = ""

    const query = this.inputTarget.value.trim()
    if (query && query.length >= this.minLengthValue) {
      this.fetchResults(query)
    } else {
      if (this.hasUrlValue) {
        this.hideAndRemoveOptions()
      } else {
        // We will show full list if we have prefetched list
        this.fetchResults(query)
      }
    }
  }

  identifyOptions() {
    let id = 0
    const optionsWithoutId = this.resultsTarget.querySelectorAll(`${optionSelector}:not([id])`)
    optionsWithoutId.forEach((el) => {
      el.id = `${this.resultsTarget.id}-option-${id++}`
    })
  }

  hideAndRemoveOptions() {
    this.close()
    if (this.hasUrlValue) this.resultsTarget.innerHTML = null
  }

  filterPreloadedList() {
    console.log("Filtering prefetched list with", this.inputTarget.value.trim())
    Array.from(this.resultsTarget.children).forEach(e => {
      if (!e.dataset.autocompleteLabel) return
      if ((this.inputTarget.value.trim() == "") || e.dataset.autocompleteLabel.toLowerCase().includes(this.inputTarget.value.trim().toLowerCase())) e.classList.remove("d-none") 
      else e.classList.add("d-none") 
    });
  }

  fetchResults = async () => {

    if (!this.hasUrlValue) {
      // Results should already be preloaded
      console.log("Showing up preloaded list as there is not url")
      this.filterPreloadedList()
      this.open()
      return
    }
    const url = this.buildQueryURL()

    try {
      this.element.dispatchEvent(new CustomEvent("loadstart"))
      const html = await this.doFetch(url)
      this.replaceResults(html)
      this.element.dispatchEvent(new CustomEvent("load"))
      this.element.dispatchEvent(new CustomEvent("loadend"))
    } catch(error) {
      this.element.dispatchEvent(new CustomEvent("error"))
      this.element.dispatchEvent(new CustomEvent("loadend"))
      throw error
    }
  }

  buildQueryURL() {
    const query = this.inputTarget.value.trim()
    if ((!query || query.length < this.minLengthValue) && (!this.prefetchValue)) {
      this.hideAndRemoveOptions()
      return null
    }
    const url = new URL(this.urlValue, window.location.href)
    const params = new URLSearchParams(url.search.slice(1))
    if (this.paramsValue) {
      Object.entries(this.paramsValue).forEach((entry) => {
        params.append(entry[0], entry[1])
      })
    }
    let need_query = true
    params.forEach((value, key) => {
      if (value == "[query]") {
        params.set(key, query)
        need_query = false
      }
    });
    if (need_query) params.append("q", query)
    url.search = params.toString()
    return url.toString()
  }

  doFetch = async (url) => {
    const response = await fetch(url, this.optionsForFetch())
    const html = await response.text()
    return html
  }

  replaceResults(html) {

    this.resultsTarget.innerHTML = html
    this.identifyOptions()
    if (!!this.options) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    if (this.resultsShown) return

    this.resultsShown = true
    this.element.setAttribute("aria-expanded", "true")
    this.element.dispatchEvent(
      new CustomEvent("toggle", {
        detail: { action: "open", inputTarget: this.inputTarget, resultsTarget: this.resultsTarget }
      })
    )
  }

  close() {
    if (!this.resultsShown) return

    this.resultsShown = false
    this.inputTarget.removeAttribute("aria-activedescendant")
    this.element.setAttribute("aria-expanded", "false")

    this.element.dispatchEvent(
      new CustomEvent("toggle", {
        detail: { action: "close", inputTarget: this.inputTarget, resultsTarget: this.resultsTarget }
      })
    )
  }

  get resultsShown() {
    return !this.resultsTarget.hidden
  }

  set resultsShown(value) {
    this.resultsTarget.hidden = !value
  }

  get options() {
    return Array.from(this.resultsTarget.querySelectorAll(optionSelector))
  }

  get selectedOption() {
    return this.resultsTarget.querySelector(activeSelector)
  }

  get selectedClassesOrDefault() {
    return this.hasSelectedClass ? this.selectedClasses : ["active"]
  }

  optionsForFetch() {
    return { headers: { "X-Requested-With": "XMLHttpRequest" } } // override if you need
  }
}

class SelectedOption extends Controller {
  static template = (name, value, label) => `<div class="selected-option" data-controller="selected-option">
    <span class="current-option-placeholder">${escapeHtml(label)}</span>
    <input type="hidden" name="${escapeHtml(name)}" value="${escapeHtml(value)}">
    <i class="cancel fa fa-times-circle" data-action="selected-option#remove"></i>
    </div>
  `

  static addTo(element, option) {
    element.insertAdjacentHTML("beforeend", option)
  }

  remove() {
    console.log("Removing", this.element)
    this.element.remove()
  }
}

const debounce = (fn, delay = 10) => {
  let timeoutId = null

  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(fn, delay)
  }
}

const escapeHtml = (unsafe) => {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
}

export { Autocomplete, SelectedOption }
