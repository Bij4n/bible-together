import { Controller } from "@hotwired/stimulus"

// Dropdown menu for the navbar's account/preferences surface. Click
// the trigger to toggle; click outside or press Escape to close.
// Keeps aria-expanded in sync so assistive tech tracks the state.
// Listeners are only bound while open to avoid a global capture on
// every page.
export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleEscape)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleEscape)
  }

  close() {
    this.menuTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
      this.triggerTarget.focus()
    }
  }
}
