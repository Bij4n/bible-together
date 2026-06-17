Rails.application.routes.draw do
  devise_for :users

  get   "/settings", to: "settings#edit",   as: :settings
  patch "/settings", to: "settings#update"

  resources :highlights, only: [ :create, :update, :destroy ]
  resources :notes,      only: [ :index, :new, :create, :update, :destroy, :show, :edit ] do
    collection do
      post :discard_draft
    end
  end

  # Sprint 23.2/23.3 — accept-via-token route for email group
  # invitations. The named helper is `accept_group_invitation_path`
  # so it doesn't collide with the nested `group_invitation_path`
  # (DELETE /groups/:group_id/invitations/:id) generated under the
  # groups resource above.
  get "/group_invitations/:token",
      to: "group_invitations#show",
      as: :accept_group_invitation

  resources :note_shares, only: [ :create, :destroy ]
  resources :comments,    only: [ :create, :update, :destroy ]
  resources :upvotes,     only: [ :create, :destroy ]
  resources :flags,       only: [ :create ]

  post "/locale_banner/dismiss", to: "locale_banners#dismiss", as: :dismiss_locale_banner

  # User-facing URL is /studies (Sprint R8); route helpers stay group_*.
  resources :groups, path: "studies" do
    collection do
      post :join
      get  :discover
    end
    member do
      delete :leave
    end
    resources :memberships, only: [ :update, :destroy ]
    # Sprint 23.3 — owner sends/cancels email invitations from the
    # group's show page. show (accept-via-token) lives at the
    # top-level path keyed by token; see below.
    resources :invitations, only: [ :create, :destroy ], controller: "group_invitations"
    get "bible/:translation/:book/:chapter",
        to: "groups/bible#show",
        as: :bible_chapter,
        constraints: { chapter: /\d+/ }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#show"
  get "/how-it-works", to: "home#how_it_works", as: :how_it_works
  get  "/contact", to: "contacts#new", as: :contact
  post "/contact", to: "contacts#create"

  get "/bible", to: "bible/reader#entry", as: :bible_entry
  get "/bible/:translation/:book/:chapter",
      to: "bible/reader#show",
      as: :bible_chapter,
      constraints: { chapter: /\d+/ }

  get "/public/bible", to: redirect("/bible/kjv/gen/1?layer=community", status: 301)
  get "/public/bible/:translation/:book/:chapter",
      to: "public/bible#show",
      as: :public_bible_chapter,
      constraints: { chapter: /\d+/ }

  get "/search", to: "search#index", as: :search

  # The global public-notes feed (Sprint R7) — "the public list of all
  # the public comments/stories on highlighted verses."
  get "/community", to: "community#index", as: :community

  # Public forum (Sprint 26) — anyone signed in can start a thread or
  # reply; reading is open to everyone. Admins can hide threads/posts.
  resources :forum_threads, path: "forum", only: %i[index show new create] do
    member do
      patch :hide
      patch :unhide
    end
    resources :forum_posts, only: [ :create ] do
      member do
        patch :hide
        patch :unhide
      end
    end
  end

  # Legacy /groups bookmarks (Sprint R8) — 301 to /studies.
  get "/groups", to: redirect("/studies", status: 301)
  get "/groups/*legacy_path", to: redirect("/studies/%{legacy_path}", status: 301)

  resources :authors, only: [ :show ] do
    # Follow the author (Sprint R5). Singular — you either follow
    # someone or you don't.
    resource :follow, only: [ :create, :destroy ]
  end

  # Vanity profile handle: /@username → the author's profile.
  get "/@:username", to: "authors#show", as: :profile, constraints: { username: /[A-Za-z0-9_]+/ }

  get  "/about",             to: "about#show",             as: :about
  get  "/terms",             to: "legal#terms",            as: :terms
  get  "/privacy",           to: "legal#privacy",          as: :privacy
  get  "/sitemap.xml",       to: "sitemap#show",           as: :sitemap, defaults: { format: :xml }

  get  "/donate",            to: "donations#show",         as: :donate
  post "/donate/confirm",    to: "donations#create_report", as: :donate_confirm
  get  "/donate/thank_you",  to: "donations#thanks",       as: :donate_thank_you

  namespace :admin do
    resources :notes, only: [ :index, :show ] do
      member do
        patch :feature
        patch :unfeature
        patch :hide
        patch :unhide
      end
    end
    resources :flags, only: [ :index ] do
      member do
        patch :resolve
      end
    end
    resources :bitcoin_addresses, only: [ :index, :new, :create ]
  end

  # Branded error pages — wired up via config.exceptions_app in
  # production.rb. Rails dispatches to these paths when an exception
  # bubbles out of the app; ErrorsController#show renders the Echo-
  # branded view through application.html.erb so the error page gets
  # the full chrome (header + footer). via: :all so non-GET requests
  # that hit a 404 path also surface the branded view, not blank
  # routing-error JSON.
  # Preview/test route for branded error pages — bypasses Rack::Static
  # which serves public/{404,...}.html directly at the canonical paths.
  # Useful for design eyeball verification of the dynamic view.
  get "/__error/:code", to: "errors#show", as: :error_preview, constraints: { code: /\d+/ }

  match "/404", to: "errors#show", via: :all, defaults: { code: 404 }, as: :error_404
  match "/422", to: "errors#show", via: :all, defaults: { code: 422 }, as: :error_422
  match "/500", to: "errors#show", via: :all, defaults: { code: 500 }, as: :error_500
  match "/400", to: "errors#show", via: :all, defaults: { code: 400 }, as: :error_400
  match "/406-unsupported-browser", to: "errors#show", via: :all, defaults: { code: 406 }, as: :error_406
end
