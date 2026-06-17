module AvatarsHelper
  include NavigationHelper
  SIZES = {
    sm: "h-8 w-8 text-xs",
    md: "h-16 w-16 text-lg",
    lg: "h-24 w-24 text-2xl",
    xl: "h-28 w-28 text-3xl"
  }.freeze

  def user_avatar(user, size: :md, extra_classes: "")
    size_classes = SIZES.fetch(size)
    base = "inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-accent-700 font-ui font-semibold text-surface-50 #{size_classes} #{extra_classes}"

    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [ 256, 256 ]),
                class: "h-full w-full object-cover",
                alt: t("avatars.photo_alt", name: user.author_name)
    else
      tag.span(user_initials(user), class: base, aria: { hidden: true })
    end
  end
end
