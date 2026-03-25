import { Controller } from "@hotwired/stimulus"

// Minimal Sprint 7 flagging: prompt() for a brief reason, POST to
// /flags. A proper modal with reason radios lands in a later sprint;
// this gets the feature into hands fast. The prompt / success /
// failure strings are passed in as Stimulus values so the ERB picks
// the current locale.
export default class extends Controller {
  static values = {
    noteId:  Number,
    prompt:  { type: String, default: "Why are you flagging this?" },
    success: { type: String, default: "Flag submitted." },
    failure: { type: String, default: "Couldn't submit. Try again later." }
  }

  async prompt() {
    const details = window.prompt(this.promptValue)
    if (!details) return

    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    const csrf = csrfMeta ? csrfMeta.content : ""

    const response = await fetch("/flags", {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrf
      },
      body: JSON.stringify({
        flag: {
          flaggable_type: "Note",
          flaggable_id: this.noteIdValue,
          reason: "other",
          details
        }
      })
    })

    window.alert(response.ok ? this.successValue : this.failureValue)
  }
}
