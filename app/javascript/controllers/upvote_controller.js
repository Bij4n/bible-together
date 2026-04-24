import { Controller } from "@hotwired/stimulus"

// Toggles the user's upvote on a note via JSON. The button visual
// state is driven off the `upvoted` value; the server is the source
// of truth for the count (returned in the response body).
export default class extends Controller {
  static targets = ["button", "count"]
  static values = {
    noteId: Number,
    upvoted: Boolean
  }

  connect() {
    this.syncButton()
  }

  async toggle() {
    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    const csrf = csrfMeta ? csrfMeta.content : ""

    const url = this.upvotedValue ? `/upvotes/${this.noteIdValue}` : "/upvotes"
    const method = this.upvotedValue ? "DELETE" : "POST"
    const body = this.upvotedValue ? null : JSON.stringify({ note_id: this.noteIdValue })

    const response = await fetch(url, {
      method,
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrf
      },
      body
    })

    if (!response.ok) return

    const data = await response.json()
    this.upvotedValue = data.upvoted
    if (this.hasCountTarget) this.countTarget.textContent = data.count
    this.syncButton()
  }

  syncButton() {
    if (!this.hasButtonTarget) return
    this.buttonTarget.classList.toggle("bg-accent-700", this.upvotedValue)
    this.buttonTarget.classList.toggle("text-surface-50", this.upvotedValue)
    this.buttonTarget.classList.toggle("dark:bg-accent-400", this.upvotedValue)
    this.buttonTarget.classList.toggle("dark:text-surface-950", this.upvotedValue)
  }
}
