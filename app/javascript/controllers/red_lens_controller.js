import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "redLensWordsOnly"
const WORDS_ONLY_CLASS = "red-lens-words-only"

// Highlighted in Red's "his words only" toggle. The page always
// carries every verse; this adds a class that hides the ones with no
// red text, so a live verse replace can't undo the reader's choice.
// The choice is remembered per browser.
export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.apply(this.stored())
  }

  toggle() {
    const wordsOnly = !this.element.classList.contains(WORDS_ONLY_CLASS)
    this.apply(wordsOnly)
    this.store(wordsOnly)
  }

  apply(wordsOnly) {
    this.element.classList.toggle(WORDS_ONLY_CLASS, wordsOnly)
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-pressed", String(wordsOnly))
    }
  }

  stored() {
    try {
      return window.localStorage.getItem(STORAGE_KEY) === "1"
    } catch {
      return false
    }
  }

  store(wordsOnly) {
    try {
      window.localStorage.setItem(STORAGE_KEY, wordsOnly ? "1" : "0")
    } catch {
      // Private windows and blocked storage: the toggle still works
      // for this page view.
    }
  }
}
