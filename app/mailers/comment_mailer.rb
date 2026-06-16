class CommentMailer < ApplicationMailer
  # Notifies a note's author when someone else comments on it. Gated in
  # CommentsController on the author's email_on_comment preference.
  def new_comment(comment)
    @comment   = comment
    @note      = comment.note
    @author    = @note.user
    @commenter = comment.user

    mail(
      to: @author.email,
      subject: t("comment_mailer.new_comment.subject", name: @commenter.author_name)
    )
  end
end
