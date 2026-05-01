import { Controller } from "@hotwired/stimulus"

// Toggles `.scrolled` on the header once the page has scrolled past
// the threshold. Used to pop the header's bottom border only when the
// header has lifted off the top of the page; combined with backdrop-
// blur in CSS, the header reads as flush at rest and as a translucent
// floating bar mid-scroll.
//
// Passive listener (won't block scroll), single threshold check, single
// classList toggle. No debouncing, no rAF — the toggle is idempotent
// and the CSS transition handles any visual smoothing.
export default class extends Controller {
  static THRESHOLD = 16

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    this.element.classList.toggle("scrolled", window.scrollY > this.constructor.THRESHOLD)
  }
}
