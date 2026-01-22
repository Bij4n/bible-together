import { Controller } from "@hotwired/stimulus"

// Navigates to the selected chapter URL on change. The <option> value is
// the bible_chapter_path computed server-side; the controller just needs
// to assign window.location.
export default class extends Controller {
  navigate(event) {
    const url = event.target.value
    if (url) Turbo.visit(url)
  }
}
